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

# Unmount USB device
unmount_ext4() {
    local mount_point="${MOUNT_POINT:-/mnt/bkp-pendrive}"
    
    if ! mountpoint -q "$mount_point" 2>/dev/null; then
        log_warn "Nenhum pendrive montado em $mount_point"
        return 1
    fi
    
    # Change out of mountpoint if we're in it
    cd "$HOME" 2>/dev/null || true
    
    sudo umount "$mount_point"
    sudo rmdir "$mount_point" 2>/dev/null || true
    
    log_success "Pendrive desmontado de $mount_point"
    return 0
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
