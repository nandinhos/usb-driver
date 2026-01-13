#!/bin/bash
# lib/tui.sh - Terminal UI helpers for usb-driver

# =========================
# Colors (with terminal detection)
# =========================
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA='' BOLD='' DIM='' NC=''
fi

# =========================
# Output functions
# =========================
print_info()    { echo -e "${BLUE}ℹ${NC}  $1"; }
print_success() { echo -e "${GREEN}✔${NC}  $1"; }
print_warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
print_error()   { echo -e "${RED}✖${NC}  $1" >&2; }
print_step()    { echo -e "\n${CYAN}▶${NC} ${BOLD}$1${NC}"; }

# =========================
# Banner
# =========================
print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║        usb-driver Installer        ║"
    echo "║     Pendrive EXT4 no WSL2            ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# =========================
# Prompts
# =========================
prompt_confirm() {
    local message="${1:-Continuar?}"
    while true; do
        read -rp "$(echo -e "${YELLOW}?${NC} ${message} [s/n]: ")" yn
        case $yn in
            [Ss]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Responda s ou n.";;
        esac
    done
}

prompt_input() {
    local message="$1"
    local default="$2"
    local result
    read -rp "$(echo -e "${BLUE}?${NC} ${message} [${default}]: ")" result
    echo "${result:-$default}"
}

prompt_wait() {
    local message="${1:-Pressione ENTER para continuar...}"
    read -rp "$(echo -e "${YELLOW}⏳${NC} ${message}")"
}

# =========================
# Menu
# =========================
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo -e "\n${BOLD}${title}${NC}"
    local i=1
    for opt in "${options[@]}"; do
        echo "  ${i}) ${opt}"
        ((i++))
    done
    echo
}
