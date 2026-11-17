#!/bin/bash
# lib/usbipd.sh - usbipd-win integration for usb-driver
# Note: USBIPD_EXE is defined in lib/constants.sh

# Check if usbipd is installed on Windows host
check_usbipd_installed() {
    # Use full path since PATH may not be set when invoked from WSL
    if powershell.exe -NoProfile -Command "& '$USBIPD_EXE' --version" &>/dev/null; then
        return 0
    fi
    return 1
}

# Get usbipd-win version string
get_usbipd_version() {
    powershell.exe -NoProfile -Command "& '$USBIPD_EXE' --version" 2>/dev/null | tr -d '\r\n'
}

# Prompt user to install usbipd-win with guidance
prompt_usbipd_install() {
    echo ""
    echo "=========================================="
    echo "  ! usbipd-win nao encontrado no Windows"
    echo "=========================================="
    echo ""
    echo "  Para instalar, abra o PowerShell como"
    echo "  Administrador e execute:"
    echo ""
    echo "    winget install usbipd"
    echo ""
    echo "=========================================="
    echo ""
    read -rp "  Pressione ENTER apos instalar... "
}

# Require usbipd with retry loop
require_usbipd() {
    if check_usbipd_installed; then
        log_success "usbipd-win detectado no Windows"
        return 0
    fi
    
    prompt_usbipd_install
    
    if check_usbipd_installed; then
        log_success "usbipd-win instalado com sucesso!"
        return 0
    else
        log_error "usbipd-win ainda não detectado."
        log_error "Instale manualmente e tente novamente: winget install usbipd"
        return 1
    fi
}

# List USB devices via usbipd
list_usb_devices() {
    powershell.exe -NoProfile -Command "& '$USBIPD_EXE' list" 2>/dev/null
}

# Bind USB device on Windows (triggers UAC elevation)
bind_usb() {
    local busid="$1"
    if ! validate_busid "$busid"; then
        log_error "BUSID inválido: $busid"
        return 1
    fi
    powershell.exe -NoProfile -Command "Start-Process -FilePath \"$USBIPD_EXE\" -ArgumentList \"bind\", \"--busid\", \"$busid\", \"--force\" -Verb RunAs -Wait" 2>/dev/null
}

# Attach USB device to WSL (raw output)
attach_usb_raw() {
    local busid="$1"
    if ! validate_busid "$busid"; then
        echo "ERROR: BUSID inválido: $busid" >&2
        return 1
    fi
    powershell.exe -NoProfile -Command "& '$USBIPD_EXE' attach --wsl --busid $busid" 2>&1
}

# Attach USB device to WSL
attach_usb() {
    local busid="$1"
    if ! validate_busid "$busid"; then
        log_error "BUSID inválido: $busid"
        return 1
    fi
    log_info "Anexando dispositivo USB (BUSID=$busid) ao WSL..."
    powershell.exe -NoProfile -Command "& '$USBIPD_EXE' bind --busid $busid; & '$USBIPD_EXE' attach --wsl --busid $busid" 2>&1
    # shellcheck disable=SC2181 # Direct $? check is clearer here
    if [ $? -eq 0 ]; then
        log_success "Dispositivo anexado ao WSL"
        return 0
    else
        log_error "Falha ao anexar dispositivo"
        return 1
    fi
}

# Detach USB device from WSL
detach_usb() {
    local busid="$1"
    if ! validate_busid "$busid"; then
        log_error "BUSID inválido: $busid"
        return 1
    fi
    log_info "Desanexando dispositivo USB (BUSID=$busid)..."
    powershell.exe -NoProfile -Command "& '$USBIPD_EXE' detach --busid $busid" 2>&1
}
