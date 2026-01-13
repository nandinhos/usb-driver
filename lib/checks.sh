#!/bin/bash
# lib/checks.sh - Environment validation for usb-driver

# =========================
# Basic Checks
# =========================

check_wsl() {
    if grep -qi microsoft /proc/version 2>/dev/null; then
        return 0
    fi
    return 1
}

check_root() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    fi
    return 1
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

# =========================
# Health Check Functions
# =========================

# Check if running in WSL2
health_check_wsl() {
    if check_wsl; then
        log_success "WSL2 detectado"
        return 0
    else
        log_error "Não está executando no WSL"
        return 1
    fi
}

# Check usbipd-win installation and version
health_check_usbipd() {
    local version
    version=$(powershell.exe -NoProfile -Command "& '$USBIPD_EXE' --version" 2>/dev/null | tr -d '\r\n')
    
    if [ -n "$version" ]; then
        log_success "usbipd-win instalado ($version)"
        return 0
    else
        log_error "usbipd-win não encontrado"
        log_hint "Instale com: winget install usbipd"
        return 1
    fi
}

# Check ntfs-3g driver
health_check_ntfs3g() {
    if check_command ntfs-3g; then
        log_success "ntfs-3g disponível"
        return 0
    else
        log_warn "ntfs-3g não instalado (necessário para discos NTFS)"
        log_hint "Instale com: sudo apt install ntfs-3g"
        return 1
    fi
}

# Check mount point configuration
health_check_mount_point() {
    local mount_point="${MOUNT_POINT:-/mnt/usb-driver}"
    
    if [ -d "$mount_point" ]; then
        if mountpoint -q "$mount_point" 2>/dev/null; then
            log_success "Mount point ativo: $mount_point"
        else
            log_success "Mount point configurado: $mount_point"
        fi
        return 0
    else
        log_info "Mount point será criado: $mount_point"
        return 0
    fi
}

# Check if any USB storage device is connected
health_check_usb_device() {
    local device
    device=$(detect_usb_device 2>/dev/null)
    
    if [ -n "$device" ]; then
        local fstype
        fstype=$(get_device_fstype "$device" 2>/dev/null)
        log_success "Dispositivo USB anexado ao WSL: $device ($fstype)"
        return 0
    else
        # Check if there are USB storage devices in Windows that can be attached
        local win_devices
        win_devices=$(powershell.exe -NoProfile -Command "& '$USBIPD_EXE' list" 2>/dev/null | \
            grep -i "Mass Storage\|Armazenamento\|UAS\|SCSI" | wc -l)
        
        if [ "$win_devices" -gt 0 ]; then
            log_warn "Dispositivo USB no Windows, mas não anexado ao WSL"
            log_hint "Execute: usb-driver up"
            return 1
        else
            log_warn "Nenhum dispositivo USB de armazenamento conectado"
            return 1
        fi
    fi
}

# Run all health checks
run_health_check() {
    local errors=0
    
    echo -e "\n${CYAN}▶${NC} ${BOLD}Verificando ambiente usb-driver...${NC}\n"
    
    health_check_wsl || ((errors++))
    health_check_usbipd || ((errors++))
    health_check_ntfs3g || true  # Not critical, just warning
    health_check_mount_point || true
    health_check_usb_device || true  # Not critical, just info
    
    echo
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✔ Ambiente pronto para uso!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Ambiente com $errors problema(s). Verifique as mensagens acima.${NC}"
        return 1
    fi
}
