#!/bin/bash
# lib/mount_ext4.sh - USB mount/unmount for usb-driver
# Supports: EXT4, NTFS, FAT32, exFAT
# Note: SUPPORTED_FS is defined in lib/constants.sh

# Non-interactive sudo when running in JSON/GUI mode so it never hangs waiting for TTY password
_sudo() {
    if ${JSON_MODE:-false}; then
        sudo -n "$@"
    else
        sudo "$@"
    fi
}

# Get parent disk for a partition (e.g., /dev/sdh1 -> /dev/sdh, /dev/nvme0n1p1 -> /dev/nvme0n1)
get_parent_disk() {
    local dev="$1"
    echo "$dev" | sed -E 's/p?[0-9]+$//'
}

# Check if a device is a system partition or already safely mounted
is_safe_device() {
    local dev="$1"
    local mnt label raw_label
    
    # Normalize path (remove trailing slash)
    local target_mnt="${MOUNT_POINT:-$DEFAULT_MOUNT_POINT}"
    target_mnt="${target_mnt%/}"
    
    mnt=$(findmnt -rpno TARGET "$dev" 2>/dev/null | head -1)
    mnt="${mnt%/}" # Normalize
    
    # 1. ABSOLUTE PATH BLACKLIST: System paths (exact or subdirectories) and Windows DrvFs (/mnt/c, etc.)
    if echo "$mnt" | grep -qE "^/$|^/(boot|etc|var|usr|bin|sbin|lib|lib64|run|dev|proc|sys|home|snap|root|opt|srv|tmp)(/|$)|^/mnt/[a-zA-Z](/|$)"; then
        return 1
    fi
    
    # 2. LABEL BLACKLIST: EFI and critical system labels
    # We removed "Windows" from here because the user's external HD might have it.
    raw_label=$(lsblk -no LABEL "$dev" 2>/dev/null | head -1)
    label=$(printf '%s' "$raw_label" | tr -d ' ')
    if echo "$label" | grep -qiE "^(SystemReserved|Recovery|EFI|boot|ESP)$"; then
        return 1
    fi
    
    # 3. IDENTIFY HOST SYSTEM DRIVE: Usually the one with "Windows" label AND Not Removable
    # If it's internal (RM=0) and named "Windows" (e.g., Windows, Windows 10, Windows 11), it's likely the host C: drive.
    # We only block it if it's NOT a USB transport.
    local rm tran
    rm=$(lsblk -no RM "$dev" 2>/dev/null | head -1)
    tran=$(lsblk -no TRAN "$dev" 2>/dev/null | head -1)
    if [[ "$label" =~ ^[Ww]indows([0-9]+)?$ && "$rm" == "0" && "$tran" != "usb" ]]; then
        return 1
    fi
    
    # 4. MOUNT POINT CHECK
    # Allow if not mounted, or if mounted inside our base MOUNT_POINT directory (or legacy one)
    [ -z "$mnt" ] && return 0
    if [[ "$mnt" == "$target_mnt" || "$mnt" == "$target_mnt/"* || "$mnt" == "$DEFAULT_MOUNT_POINT"* ]]; then
        return 0
    fi
    
    return 1
}

# Resolve Windows VID:PID to WSL device node (e.g., 04e8:6860 -> /dev/sdh1)
# Returns the partition path
find_dev_by_vidpid() {
    local vidpid="$1"
    [ -z "$vidpid" ] && return 1
    
    local vid pid
    vid=$(echo "$vidpid" | cut -d':' -f1)
    pid=$(echo "$vidpid" | cut -d':' -f2)
    
    # 1. Find the USB device path in sysfs
    local usb_path=""
    for dev_path in /sys/bus/usb/devices/*; do
        [ -f "$dev_path/idVendor" ] || continue
        if [[ "$(cat "$dev_path/idVendor")" == "$vid" && "$(cat "$dev_path/idProduct")" == "$pid" ]]; then
            usb_path=$(readlink -f "$dev_path")
            break
        fi
    done
    
    [ -z "$usb_path" ] && return 1
    
    # 2. Match it with any block device in /sys/block/sd*
    # We check if the block device's parent path is a subpath of the USB device path
    for block_path in /sys/block/sd*; do
        [ -L "$block_path/device" ] || continue
        local dev_link
        dev_link=$(readlink -f "$block_path/device")
        
        # If the block device canonical path contains the usb_path, it's our device
        if [[ "$dev_link" == "$usb_path"* ]]; then
            local block_dev
            block_dev=$(basename "$block_path")
            
            # Find the first partition on this disk that has a supported FS
            local part
            part=$(lsblk -rpno NAME,FSTYPE "/dev/$block_dev" 2>/dev/null | awk -v fs="$SUPPORTED_FS" '$2 ~ fs {print $1; exit}')
            if [ -n "$part" ]; then
                echo "$part"
                return 0
            fi
        fi
    done
    
    return 1
}

# Detect USB storage device or External HD
# Usage: detect_usb_device [vidpid]
detect_usb_device() {
    local vidpid="$1"
    local candidate=""
    
    # 1. If VID:PID provided, try direct resolution first (Pinning)
    if [ -n "$vidpid" ]; then
        candidate=$(find_dev_by_vidpid "$vidpid")
        if [ -n "$candidate" ] && is_safe_device "$candidate"; then
            echo "$candidate"
            return 0
        fi
        # If pinned search fails, we DON'T fallback to random devices
        # to prevent mounting the wrong one.
        return 1
    fi
    
    # 2. General fallback (No VID:PID provided): Scan all USB storage devices
    # Get all partitions with supported filesystems
    local parts
    parts=$(lsblk -rpno NAME,FSTYPE | awk -v fs="$SUPPORTED_FS" '$2 ~ fs {print $1}')
    
    for part in $parts; do
        # Strategy: Strict transport or RM check
        local is_usb=false
        local rm
        rm=$(lsblk -no RM "$part" 2>/dev/null | head -1)
        if [ "$rm" = "1" ]; then
            is_usb=true
        else
            local tran
            tran=$(lsblk -no TRAN "$part" 2>/dev/null | head -1)
            if [ "$tran" = "usb" ]; then
                is_usb=true
            else
                local parent
                parent=$(get_parent_disk "$part")
                tran=$(lsblk -no TRAN "$parent" 2>/dev/null | head -1)
                [ "$tran" = "usb" ] && is_usb=true
            fi
        fi
        
        if [ "$is_usb" = "true" ] && is_safe_device "$part"; then
            echo "$part"
            return 0
        fi
    done
    
    return 1
}

# List all available USB storage devices (for selection)
list_available_devices() {
    log_debug "Listing available devices (select_mode=$SELECT_MODE, simulate=$SIMULATE_MODE)"
    echo -e "\n${CYAN}▶${NC} ${BOLD}Dispositivos de Armazenamento USB Disponíveis${NC}\n" >&2
    
    # Header
    printf "  %-12s %-8s %-15s %-10s %-10s\n" "DISPOSITIVO" "TIPO" "LABEL" "TAMANHO" "STATUS" >&2
    echo "  ────────────────────────────────────────────────────────────" >&2
    
    local count=0
    local target_mnt="${MOUNT_POINT:-/mnt/usb-driver}"
    target_mnt="${target_mnt%/}"
    
    # Use the inventory from select_usb_device logic but for display
    # We only show what is ALREADY in WSL and SAFE
    local pot_devs
    pot_devs=$(lsblk -rpno NAME,FSTYPE,TYPE | awk -v fs="$SUPPORTED_FS" '$3=="part" && $2 ~ fs {print $1}')
    
    for dev in $pot_devs; do
        is_safe_device "$dev" || continue

        # Check if USB (self or parent)
        local is_usb=false
        local rm
        rm=$(lsblk -no RM "$dev" 2>/dev/null | head -1)
        if [ "$rm" = "1" ]; then
            is_usb=true
        else
            local tran
            tran=$(lsblk -no TRAN "$dev" 2>/dev/null | head -1)
            if [ "$tran" = "usb" ]; then
                is_usb=true
            else
                local parent
                parent=$(get_parent_disk "$dev")
                tran=$(lsblk -no TRAN "$parent" 2>/dev/null | head -1)
                [ "$tran" = "usb" ] && is_usb=true
            fi
        fi
        
        [ "$is_usb" = "false" ] && continue
        
        # Get metadata
        local fs size label mnt status
        fs=$(lsblk -no FSTYPE "$dev" 2>/dev/null | head -1)
        size=$(lsblk -no SIZE "$dev" 2>/dev/null | head -1)
        label=$(lsblk -no LABEL "$dev" 2>/dev/null | head -1)
        [ -z "$label" ] && label="-"
        
        # Check mount status
        mnt=$(findmnt -rpno TARGET "$dev" 2>/dev/null | head -1)
        mnt="${mnt%/}"
        
        if [ -n "$mnt" ]; then
            if [[ "$mnt" == "$target_mnt"* ]]; then
                # Show relative path if it's a subdirectory
                local rel_mnt="${mnt#"$target_mnt"}"
                rel_mnt="${rel_mnt#/}"
                if [ -n "$rel_mnt" ]; then
                    status="${GREEN}Montado em $rel_mnt${NC}"
                else
                    status="${GREEN}Montado (Raiz)${NC}"
                fi
            else
                status="${YELLOW}Em uso por outro sistema${NC}"
            fi
        else
            status="${CYAN}Disponível${NC}"
        fi
        
        printf "  %-12s %-8s %-15s %-10s " "$dev" "$fs" "$label" "$size" >&2
        echo -e "$status" >&2
        ((count++)) || true
    done
    
    if [ $count -eq 0 ]; then
        log_warn "Nenhum dispositivo USB anexado ao WSL" >&2
    else
        echo -e "  ${BOLD}Total no WSL: $count dispositivo(s)${NC}" >&2
    fi
    
    # Also show Windows USB storage devices that can be attached
    log_debug "Scanning Windows USB devices using usbipd..."
    echo -e "\n${CYAN}▶${NC} ${BOLD}Dispositivos USB no Windows (disponíveis para anexar)${NC}\n" >&2
    
    local win_count=0
    
    # Filter only lines starting with BUSID pattern, and filter storage devices
    while IFS= read -r line; do
        local busid vidpid desc state
        
        busid=$(echo "$line" | awk '{print $1}')
        [[ ! "$busid" =~ ^[0-9]+-[0-9]+$ ]] && continue

        state=$(parse_usbipd_state "$line")
        
        # Skip if already attached
        [[ "$state" == "Attached" ]] && continue
        
        # Get device name (truncate if too long)
        desc=$(echo "$line" | awk '{for(i=3;i<NF;i++) printf "%s ", $i; print ""}' | cut -c1-45)
        
        # Display with proper formatting
        local status_text
        if [[ "$state" == "Shared" ]]; then
            status_text="${GREEN}✓ Pronto${NC}"
        else
            status_text="${YELLOW}⚠ Bind first${NC}"
        fi
        
        printf "  %-7s %-45s " "$busid" "$desc" >&2
        echo -e "$status_text" >&2
        ((win_count++)) || true
    done < <(list_usb_devices | grep -i "$USB_STORAGE_FILTER" || true)
    
    if [ $win_count -eq 0 ]; then
        log_info "Nenhum dispositivo USB adicional no Windows" >&2
    else
        echo -e "\n  Para anexar: usb-driver attach <BUSID>" >&2
        echo -e "  Exemplo: usb-driver attach 2-4" >&2
    fi
}

# Detect device by LABEL (optional)
detect_device_by_label() {
    local label="$1"
    local device
    device=$(lsblk -rpno NAME,LABEL,FSTYPE | awk -v lbl="$label" -v fs="$SUPPORTED_FS" '
        $2==lbl && $3 ~ fs {print $1; exit}
    ')
    echo "$device"
}

# Get filesystem type of device
get_device_fstype() {
    local device="$1"
    local fs
    fs=$(lsblk -no FSTYPE "$device" 2>/dev/null | head -1)
    if [ -n "$fs" ]; then
        echo "$fs"
        return 0
    fi
    _sudo blkid -o value -s TYPE "$device" 2>/dev/null
}

# Mount USB device (any supported filesystem)
mount_ext4() {
    local device="$1"
    local mount_name="$2"
    local base_mount="${MOUNT_POINT:-/mnt/usb-driver}"
    base_mount="${base_mount%/}"
    
    # REQUIRE a subdirectory name to keep the HUB structure clean
    if [ -z "$mount_name" ]; then
        log_error "Erro interno: mount_name é obrigatório na v0.4.5+"
        return 1
    fi
    
    mount_name=$(sanitize_mount_name "$mount_name" "usb-device")
    local mount_point="$base_mount/$mount_name"
    
    # Get filesystem type
    local fstype
    fstype=$(get_device_fstype "$device")
    
    if [ -z "$fstype" ]; then
        log_error "Não foi possível detectar o sistema de arquivos de $device"
        return 1
    fi
    
    log_info "Sistema de arquivos detectado: $fstype"
    
    # Check if already mounted
    if mountpoint -q "$mount_point" 2>/dev/null; then
        log_warn "Já existe algo montado em ${YELLOW}${MOUNT_POINT}/${NC}${CYAN}$(basename "$mount_point")${NC}"
        return 1
    fi
    
    # Double check if device is already mounted elsewhere
    local current_mnt
    current_mnt=$(findmnt -rpno TARGET "$device" 2>/dev/null | head -1)
    if [ -n "$current_mnt" ]; then
        log_warn "O dispositivo ${CYAN}$device${NC} já está montado em ${YELLOW}$current_mnt${NC}"
        return 1
    fi
    
    # Pre-flight driver checks before creating mount directory
    if [[ "$fstype" == "exfat" ]] && ! grep -qw exfat /proc/filesystems 2>/dev/null && ! command -v mount.exfat-fuse &>/dev/null; then
        log_error "Suporte a exFAT ausente no WSL2. Instale com: sudo apt install exfat-fuse exfatprogs"
        return 1
    fi

    # Create mountpoint
    _sudo mkdir -p "$mount_point"
    
    # Mount based on filesystem type
    case "$fstype" in
        ext4|ext3|ext2)
            _sudo mount "$device" "$mount_point"
            ;;
        ntfs|fuseblk)
            if command -v ntfs-3g &>/dev/null; then
                _sudo ntfs-3g "$device" "$mount_point" -o "rw,uid=$(id -u),gid=$(id -g)"
            else
                log_error "Driver ntfs-3g não encontrado. Por favor, instale-o: sudo apt install ntfs-3g"
                return 1
            fi
            ;;
        vfat)
            _sudo mount "$device" "$mount_point" -o "uid=$(id -u),gid=$(id -g)"
            ;;
        exfat)
            if grep -qw exfat /proc/filesystems 2>/dev/null; then
                _sudo mount "$device" "$mount_point" -o "uid=$(id -u),gid=$(id -g)"
            elif command -v mount.exfat-fuse &>/dev/null; then
                _sudo mount.exfat-fuse "$device" "$mount_point" -o "uid=$(id -u),gid=$(id -g)"
            else
                log_error "Suporte a exFAT ausente no WSL2. Instale com: sudo apt install exfat-fuse exfatprogs"
                return 1
            fi
            ;;
        *)
            _sudo mount "$device" "$mount_point"
            ;;
    esac
    
    # shellcheck disable=SC2181 # Case statement prevents direct check
    if [ $? -ne 0 ]; then
        log_error "Falha ao montar $device"
        return 1
    fi
    
    log_success "Pendrive montado em ${YELLOW}${MOUNT_POINT}/${NC}${CYAN}$(basename "$mount_point")${NC} ($fstype)"
    return 0
}

# Find Windows BUSID for a WSL device (e.g., /dev/sdg1 -> 2-16)
find_busid_by_dev() {
    local dev="$1"
    [ -z "$dev" ] && return 1
    
    # Get the parent disk if it's a partition
    local disk
    disk=$(get_parent_disk "$dev")
    
    # Find the USB device path in sysfs for this disk
    local dev_link
    dev_link=$(readlink -f "/sys/block/$(basename "$disk")/device" 2>/dev/null) || true
    [ -z "$dev_link" ] && return 0
    
    # Locate idVendor/idProduct recursively up to the USB bus level
    local vid pid d="$dev_link"
    while [ "$d" != "/" ]; do
        if [ -f "$d/idVendor" ] && [ -f "$d/idProduct" ]; then
            vid=$(cat "$d/idVendor")
            pid=$(cat "$d/idProduct")
            break
        fi
        d=$(dirname "$d")
    done
    
    if [ -n "$vid" ] && [ -n "$pid" ]; then
        list_usb_devices | grep -i "Attached" | grep -i "$vid:$pid" | head -1 | awk '{print $1}'
    fi
}

# Usage: safe_unmount [path] [--force] [--eject]
safe_unmount() {
    local target_path="$1"
    local base_mount="${MOUNT_POINT:-/mnt/usb-driver}"
    base_mount="${base_mount%/}"
    
    # If no path provided or first arg is an option, assume base_mount
    if [[ -z "$target_path" || "$target_path" == "--"* ]]; then
        target_path="$base_mount"
    fi
    
    # Shift if first arg was a path
    if [[ "$1" != "--"* && -n "$1" ]]; then
        shift
    fi

    local force=false
    local eject=false
    
    # shellcheck disable=SC2034 # eject is reserved for future functionality
    # Parse remaining arguments
    for arg in "$@"; do
        case "$arg" in
            --force) force=true ;;
            --eject) eject=true ;;
            *)
                log_warn "Argumento desconhecido para safe_unmount: $arg"
                ;;
        esac
    done
    
    if ! mountpoint -q "$target_path" 2>/dev/null; then
        log_warn "Nenhum dispositivo montado em ${YELLOW}$target_path${NC}"
        return 1
    fi
    
    # Get device before unmounting
    local device
    device=$(findmnt -n -o SOURCE "$target_path" 2>/dev/null)
    
    # Step 1: Sync writes
    log_info "Sincronizando dados de $target_path..."
    ( sync ) &
    sleep 2
    
    # Step 2: Check for processes
    log_debug "Checking for processes using $target_path..."
    local procs
    procs=$(timeout 3 fuser -m "$target_path" 2>/dev/null || true)
    
    if [ -n "$procs" ]; then
        log_warn "Processos usando o dispositivo em $target_path: PIDs $procs"
        if ! $force; then
            log_error "Use --force para desmontar mesmo assim"
            return 1
        fi
        log_warn "Forçando desmontagem..."
    fi
    
    # Step 3: Change out of mountpoint
    cd "$HOME" 2>/dev/null || true
    
    # Step 4: Unmount
    if $force; then
        _sudo umount -f "$target_path"
    else
        _sudo umount "$target_path"
    fi
    
    # shellcheck disable=SC2181 # Conditional mount prevents direct check
    if [ $? -ne 0 ]; then
        log_error "Falha ao desmontar $target_path"
        return 1
    fi
    
    # Remove subdirectory if it's not the base mount
    if [ "$target_path" != "$base_mount" ]; then
        _sudo rmdir "$target_path" 2>/dev/null || true
    fi
    
    log_success "Dispositivo desmontado de $target_path"
    
    # Step 5: Detach specific device from WSL when --eject is requested
    if $eject && [ -n "$device" ]; then
        log_info "Desanexando dispositivo do WSL..."
        local busid
        # Use subshell with || true to prevent script exit if device is gone
        busid=$(find_busid_by_dev "$device" 2>/dev/null || echo "")
        
        if [ -n "$busid" ] && validate_busid "$busid"; then
            detach_usb "$busid" >/dev/null 2>&1 || true
            log_success "Dispositivo $busid desanexado do WSL"
        else
            log_warn "Não foi possível encontrar o BUSID para desanexar o dispositivo $device"
        fi
    fi
    
    return 0
}

# JSON output for available WSL and Windows USB devices
list_available_devices_json() {
    local target_mnt="${MOUNT_POINT:-$DEFAULT_MOUNT_POINT}"
    target_mnt="${target_mnt%/}"

    if ${SIMULATE_MODE:-false}; then
        cat << 'EOF'
{"wslDevices":[{"device":"/dev/sdb1","fstype":"ext4","label":"BACKUP_LINUX","size":"64G","mountPoint":"/mnt/usb-driver/BACKUP_LINUX","status":"mounted"}],"windowsDevices":[{"busid":"2-15","vidpid":"058f:6387","description":"USB Mass Storage Device","state":"Shared"},{"busid":"2-16","vidpid":"24a9:205a","description":"SanDisk Ultra USB 3.0","state":"NotShared"}]}
EOF
        return 0
    fi

    local wsl_json="" first_wsl=true
    local pot_devs
    pot_devs=$(lsblk -rpno NAME,FSTYPE,TYPE 2>/dev/null | awk -v fs="$SUPPORTED_FS" '$3=="part" && $2 ~ fs {print $1}')

    for dev in $pot_devs; do
        is_safe_device "$dev" || continue

        local is_usb=false rm tran parent
        rm=$(lsblk -no RM "$dev" 2>/dev/null | head -1)
        if [ "$rm" = "1" ]; then
            is_usb=true
        else
            tran=$(lsblk -no TRAN "$dev" 2>/dev/null | head -1)
            if [ "$tran" = "usb" ]; then
                is_usb=true
            else
                parent=$(get_parent_disk "$dev")
                tran=$(lsblk -no TRAN "$parent" 2>/dev/null | head -1)
                [ "$tran" = "usb" ] && is_usb=true
            fi
        fi
        [ "$is_usb" = "false" ] && continue

        local fs size label mnt status
        fs=$(lsblk -no FSTYPE "$dev" 2>/dev/null | head -1)
        size=$(lsblk -no SIZE "$dev" 2>/dev/null | head -1)
        label=$(lsblk -no LABEL "$dev" 2>/dev/null | head -1)
        mnt=$(findmnt -rpno TARGET "$dev" 2>/dev/null | head -1)
        mnt="${mnt%/}"

        if [ -n "$mnt" ]; then
            if [[ "$mnt" == "$target_mnt"* ]]; then
                status="mounted"
            else
                status="in_use"
            fi
        else
            status="available"
        fi

        $first_wsl || wsl_json+=","
        first_wsl=false
        wsl_json+=$(printf '{"device":"%s","fstype":"%s","label":"%s","size":"%s","mountPoint":"%s","status":"%s"}' \
            "$(json_escape "$dev")" "$(json_escape "$fs")" "$(json_escape "$label")" \
            "$(json_escape "$size")" "$(json_escape "$mnt")" "$(json_escape "$status")")
    done

    local win_json="" first_win=true
    while IFS= read -r line; do
        local busid vidpid desc state
        busid=$(echo "$line" | awk '{print $1}')
        validate_busid "$busid" || continue
        vidpid=$(echo "$line" | awk '{print $2}')
        state=$(parse_usbipd_state "$line")
        desc=$(echo "$line" | awk '{for(i=3;i<NF;i++) printf "%s ", $i}' | sed 's/[[:space:]]*$//')

        $first_win || win_json+=","
        first_win=false
        win_json+=$(printf '{"busid":"%s","vidpid":"%s","description":"%s","state":"%s"}' \
            "$(json_escape "$busid")" "$(json_escape "$vidpid")" "$(json_escape "$desc")" "$(json_escape "$state")")
    done < <(list_usb_devices | grep -i "$USB_STORAGE_FILTER" || true)

    printf '{"wslDevices":[%s],"windowsDevices":[%s]}\n' "$wsl_json" "$win_json"
}

# Alias for backward compatibility
unmount_ext4() {
    safe_unmount "$@"
}

# Check mount status
check_mount_status() {
    local mount_point="${MOUNT_POINT:-/mnt/usb-driver}"
    
    if mountpoint -q "$mount_point" 2>/dev/null; then
        local device fstype
        device=$(findmnt -n -o SOURCE "$mount_point" 2>/dev/null)
        fstype=$(findmnt -n -o FSTYPE "$mount_point" 2>/dev/null)
        log_success "Pendrive montado: $device -> $mount_point ($fstype)"
        return 0
    else
        log_warn "Nenhum pendrive montado"
        return 1
    fi
}
