#!/bin/bash
# lib/mount_ext4.sh - USB mount/unmount for bkp-pendrive
# Supports: EXT4, NTFS, FAT32, exFAT

# Supported filesystems
SUPPORTED_FS="ext4|ntfs|vfat|exfat|fuseblk"

# Detect any removable USB device or External HD
# SAFETY: Never return devices that are already mounted or system partitions
detect_usb_device() {
    local device
    local candidate
    
    # Strategy 1: Removable devices (Pendrives) - RM=1 flag
    candidate=$(lsblk -rpno NAME,FSTYPE,RM,TYPE,TRAN | awk -v fs="$SUPPORTED_FS" '
        $3=="1" && $2 ~ fs {print $1; exit}
    ')
    
    # Strategy 2: USB transport devices (External HDs often appear as RM=0 but TRAN=usb)
    if [ -z "$candidate" ]; then
        candidate=$(lsblk -rpno NAME,FSTYPE,TRAN,TYPE | awk -v fs="$SUPPORTED_FS" '
            $3=="usb" && $4=="part" && $2 ~ fs {print $1; exit}
            $3=="usb" && $4=="disk" && $2 ~ fs {print $1; exit}
        ')
    fi
    
    # SAFETY CHECK: Ensure candidate is NOT already mounted
    if [ -n "$candidate" ]; then
        local current_mount
        current_mount=$(findmnt -n -o TARGET "$candidate" 2>/dev/null)
        
        # If device is already mounted somewhere OTHER than our mount point, reject it
        if [ -n "$current_mount" ] && [ "$current_mount" != "${MOUNT_POINT:-/mnt/bkp-pendrive}" ]; then
            # This device is mounted elsewhere (likely a system partition)
            return 1
        fi
        
        device="$candidate"
    fi
    
    if [ -z "$device" ]; then
        return 1
    fi
    echo "$device"
}

# List all available USB storage devices (for selection)
list_available_devices() {
    echo -e "\n${CYAN}▶${NC} ${BOLD}Dispositivos de Armazenamento USB Disponíveis${NC}\n"
    
    # Header
    printf "  %-12s %-8s %-15s %-10s %-10s\n" "DISPOSITIVO" "TIPO" "LABEL" "TAMANHO" "STATUS"
    echo "  ────────────────────────────────────────────────────────────"
    
    local count=0
    local mount_point="${MOUNT_POINT:-/mnt/bkp-pendrive}"
    
    # Get list of USB/removable devices with partitions
    for dev in $(lsblk -rpno NAME,RM | awk '$2=="1" {print $1}' | grep -E "sd[a-z][0-9]+" || true); do
        local fs size label mnt status
        
        # Get filesystem type
        fs=$(lsblk -no FSTYPE "$dev" 2>/dev/null | head -1)
        [ -z "$fs" ] && continue  # Skip if no filesystem
        
        # Get size and label
        size=$(lsblk -no SIZE "$dev" 2>/dev/null | head -1)
        label=$(lsblk -no LABEL "$dev" 2>/dev/null | head -1)
        [ -z "$label" ] && label="-"
        
        # Check mount status
        mnt=$(findmnt -n -o TARGET "$dev" 2>/dev/null)
        if [ -n "$mnt" ]; then
            if [ "$mnt" = "$mount_point" ]; then
                status="${GREEN}Montado${NC}"
            else
                status="${YELLOW}Em uso${NC}"
            fi
        else
            status="${CYAN}Disponível${NC}"
        fi
        
        printf "  %-12s %-8s %-15s %-10s " "$dev" "$fs" "$label" "$size"
        echo -e "$status"
        ((count++)) || true
    done
    
    # Also check USB transport devices (External HDs with RM=0 but TRAN=usb)
    for dev in $(lsblk -rpno NAME,TRAN | awk '$2=="usb" {print $1}' | grep -E "sd[a-z][0-9]+"); do
        local fs size label mnt status
        
        fs=$(lsblk -no FSTYPE "$dev" 2>/dev/null | head -1)
        [ -z "$fs" ] && continue
        
        size=$(lsblk -no SIZE "$dev" 2>/dev/null | head -1)
        label=$(lsblk -no LABEL "$dev" 2>/dev/null | head -1)
        [ -z "$label" ] && label="-"
        
        mnt=$(findmnt -n -o TARGET "$dev" 2>/dev/null)
        if [ -n "$mnt" ]; then
            if [ "$mnt" = "$mount_point" ]; then
                status="${GREEN}Montado${NC}"
            else
                status="${YELLOW}Em uso${NC}"
            fi
        else
            status="${CYAN}Disponível${NC}"
        fi
        
        printf "  %-12s %-8s %-15s %-10s " "$dev" "$fs" "$label" "$size"
        echo -e "$status"
        ((count++)) || true
    done
    
    echo
    
    if [ $count -eq 0 ]; then
        log_warn "Nenhum dispositivo USB anexado ao WSL"
    else
        echo -e "  ${BOLD}Total no WSL: $count dispositivo(s)${NC}"
    fi
    
    # Also show Windows USB storage devices that can be attached
    echo -e "\n${CYAN}▶${NC} ${BOLD}Dispositivos USB no Windows (disponíveis para anexar)${NC}\n"
    
    local win_count=0
    
    # Filter only lines starting with BUSID pattern, and filter storage devices
    while IFS= read -r line; do
        local busid vidpid desc state
        
        # Parse line components
        busid=$(echo "$line" | awk '{print $1}')
        
        # Skip lines that don't have BUSID format (X-Y pattern)
        [[ ! "$busid" =~ ^[0-9]+-[0-9]+$ ]] && continue
        
        vidpid=$(echo "$line" | awk '{print $2}')
        state=$(echo "$line" | awk '{print $NF}')
        
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
        
        echo -e "  ${BOLD}$busid${NC}  $desc  $status_text"
        ((win_count++)) || true
        
    done < <(powershell.exe -NoProfile -Command "& '$USBIPD_EXE' list" 2>/dev/null | grep -i "Mass Storage\|Armazenamento\|UAS\|SCSI" || true)
    
    echo
    
    if [ $win_count -gt 0 ]; then
        echo -e "  ${BOLD}Para anexar:${NC} bkp-pendrive attach <BUSID>"
        echo -e "  ${BOLD}Exemplo:${NC} bkp-pendrive attach 2-16"
    else
        if [ $count -eq 0 ]; then
            log_hint "Conecte um dispositivo USB ou verifique 'usbipd list' no Windows"
        fi
    fi
    
    echo
    return 0
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
    sudo blkid -o value -s TYPE "$device" 2>/dev/null
}

# Mount USB device (any supported filesystem)
mount_ext4() {
    local device="$1"
    local mount_point="${MOUNT_POINT:-/mnt/bkp-pendrive}"
    
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
        log_warn "Já existe algo montado em $mount_point"
        return 1
    fi
    
    # Create mountpoint
    sudo mkdir -p "$mount_point"
    
    # Mount based on filesystem type
    case "$fstype" in
        ext4|ext3|ext2)
            sudo mount "$device" "$mount_point"
            ;;
        ntfs|fuseblk)
            # NTFS needs ntfs-3g for write support
            if ! command -v ntfs-3g &>/dev/null; then
                log_warn "O driver 'ntfs-3g' é necessário para montar este dispositivo."
                echo
                log_info "Abra outro terminal e execute:"
                echo -e "    ${BOLD}sudo apt update && sudo apt install ntfs-3g${NC}"
                echo
                echo "=========================================="
                echo "  Pressione ENTER após instalar..."
                echo "=========================================="
                read -r
            fi
            
            if command -v ntfs-3g &>/dev/null; then
                sudo ntfs-3g "$device" "$mount_point" -o rw,uid=$(id -u),gid=$(id -g)
            else
                log_error "Driver ntfs-3g ainda não encontrado. Abortando."
                return 1
            fi
            ;;
        vfat|exfat)
            sudo mount "$device" "$mount_point" -o uid=$(id -u),gid=$(id -g)
            ;;
        *)
            sudo mount "$device" "$mount_point"
            ;;
    esac
    
    if [ $? -ne 0 ]; then
        log_error "Falha ao montar $device"
        return 1
    fi
    
    log_success "Pendrive montado em $mount_point ($fstype)"
    return 0
}

# Safe Unmount USB device
# Usage: safe_unmount [--force] [--eject]
safe_unmount() {
    local mount_point="${MOUNT_POINT:-/mnt/bkp-pendrive}"
    local force=false
    local eject=false
    
    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --force) force=true ;;
            --eject) eject=true ;;
        esac
    done
    
    if ! mountpoint -q "$mount_point" 2>/dev/null; then
        log_warn "Nenhum dispositivo montado em $mount_point"
        return 1
    fi
    
    # Get device before unmounting
    local device
    device=$(findmnt -n -o SOURCE "$mount_point" 2>/dev/null)
    
    # Step 1: Sync writes (fire-and-forget with short wait, then continue)
    log_info "Sincronizando dados..."
    # Run sync in background and wait briefly - don't block on slow USB
    ( sync ) &
    sleep 2  # Give sync 2 seconds to complete common cases
    log_success "Dados sincronizados"
    
    # Step 2: Check for processes using the mount point (fast check with fuser + timeout)
    local procs
    procs=$(timeout 3 fuser -m "$mount_point" 2>/dev/null || true)
    
    if [ -n "$procs" ]; then
        log_warn "Processos usando o dispositivo: PIDs $procs"
        
        if ! $force; then
            log_error "Use --force para desmontar mesmo assim"
            return 1
        fi
        log_warn "Forçando desmontagem..."
    fi
    
    # Step 3: Change out of mountpoint if we're in it
    cd "$HOME" 2>/dev/null || true
    
    # Step 4: Unmount
    if $force; then
        sudo umount -f "$mount_point"
    else
        sudo umount "$mount_point"
    fi
    
    if [ $? -ne 0 ]; then
        log_error "Falha ao desmontar"
        return 1
    fi
    
    sudo rmdir "$mount_point" 2>/dev/null || true
    log_success "Dispositivo desmontado de $mount_point"
    
    # Step 5: Optional eject (detach from WSL)
    if $eject && [ -n "$device" ]; then
        log_info "Ejetando dispositivo do WSL..."
        # Find BUSID from the persisted devices
        local busid
        busid=$(powershell.exe -NoProfile -Command "& '$USBIPD_EXE' list" 2>/dev/null | \
            grep -i "Attached" | head -1 | awk '{print $1}')
        
        if [ -n "$busid" ]; then
            powershell.exe -NoProfile -Command "& '$USBIPD_EXE' detach --busid $busid" 2>/dev/null
            log_success "Dispositivo ejetado do WSL (pode remover com segurança)"
        fi
    fi
    
    return 0
}

# Alias for backward compatibility
unmount_ext4() {
    safe_unmount "$@"
}

# Check mount status
check_mount_status() {
    local mount_point="${MOUNT_POINT:-/mnt/bkp-pendrive}"
    
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
