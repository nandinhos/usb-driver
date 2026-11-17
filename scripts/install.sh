#!/usr/bin/env bash
# usb-driver Installer Wizard
set -e

# =========================
# Paths
# =========================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# =========================
# Colors (with terminal detection)
# =========================
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# =========================
# Output helpers
# =========================
print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; }
print_step()    { echo -e "\n${CYAN}▶${NC} ${BOLD}$1${NC}"; }

# =========================
# Banner
# =========================
print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}         ${BOLD}usb-driver${NC} Installer         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}         Pendrive USB no WSL2         ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""
}

# =========================
# Config
# =========================
PROJECT_NAME="usb-driver"
BIN_PATH="$PROJECT_ROOT/bin/$PROJECT_NAME"
LIB_DIR="$PROJECT_ROOT/lib"
CONFIG_DIR="$HOME/.config/usb-driver"
CONFIG_FILE="$CONFIG_DIR/config"
SYMLINK="/usr/local/bin/$PROJECT_NAME"

# Defaults
DEFAULT_MOUNT_POINT="/mnt/usb-driver"
# shellcheck disable=SC2034 # Reserved for future configuration
DEFAULT_LABEL=""

# Modes
CHECK_ONLY=false
DRY_RUN=false

# =========================
# Argument parsing
# =========================
for arg in "$@"; do
    case "$arg" in
        --check)
            CHECK_ONLY=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Uso: ./install.sh [--check|--dry-run|--help]"
            echo
            echo "Opções:"
            echo "  --check    Apenas verifica requisitos"
            echo "  --dry-run  Simula instalação"
            echo "  --help     Mostra esta ajuda"
            exit 0
            ;;
    esac
done

# =========================
# Helper: run command (no eval)
# =========================
run() {
    if $CHECK_ONLY; then
        return 0
    fi
    if $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
        return 0
    fi
    "$@"
}

# =========================
# Check usbipd-win
# =========================
USBIPD_EXE='C:\Program Files\usbipd-win\usbipd.exe'

check_usbipd_windows() {
    # Use full path since PATH may not be set when invoked from WSL
    if powershell.exe -NoProfile -Command "& '$USBIPD_EXE' --version" &>/dev/null; then
        return 0
    fi
    return 1
}

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

# =========================
# Main
# =========================
main() {
    print_banner
    
    if $CHECK_ONLY; then
        print_info "Modo CHECK — nenhuma alteração será feita"
    fi
    if $DRY_RUN; then
        print_info "Modo DRY-RUN — ações serão simuladas"
    fi
    
    # ---------------------
    # Step 1: Validações
    # ---------------------
    print_step "Validando ambiente..."
    
    # Check WSL
    if ! grep -qi microsoft /proc/version; then
        print_error "Este instalador deve ser executado dentro do WSL"
        exit 1
    fi
    print_success "Executando no WSL"
    
    # Check bin exists
    if [ ! -f "$BIN_PATH" ]; then
        print_error "Arquivo bin/$PROJECT_NAME não encontrado"
        exit 1
    fi
    print_success "Arquivos do projeto encontrados"
    
    # Check sudo
    if ! command -v sudo >/dev/null; then
        print_error "sudo não encontrado"
        exit 1
    fi
    print_success "sudo disponível"
    
    # ---------------------
    # Step 2: usbipd-win
    # ---------------------
    print_step "Verificando usbipd-win no Windows..."
    
    if check_usbipd_windows; then
        print_success "usbipd-win detectado"
    else
        prompt_usbipd_install
        
        if check_usbipd_windows; then
            print_success "usbipd-win detectado após instalação"
        else
            print_error "usbipd-win ainda não detectado"
            print_info "Instale manualmente: winget install usbipd"
            print_info "Depois execute o instalador novamente"
            exit 1
        fi
    fi
    
    # ---------------------
    # Step 3: Configuração interativa
    # ---------------------
    if ! $CHECK_ONLY; then
        echo
        print_step "Configuração"
        echo
        
        # Mount point
        read -rp "$(echo -e "${BLUE}?${NC} Mount point [${DEFAULT_MOUNT_POINT}]: ")" MOUNT_POINT
        MOUNT_POINT="${MOUNT_POINT:-$DEFAULT_MOUNT_POINT}"
        if [[ ! "$MOUNT_POINT" =~ ^/[[:alnum:]._/-]+$ || "$MOUNT_POINT" == *".."* ]]; then
            print_warn "Mount point inválido. Usando padrão: $DEFAULT_MOUNT_POINT"
            MOUNT_POINT="$DEFAULT_MOUNT_POINT"
        fi
        
        # Label (optional)
        read -rp "$(echo -e "${BLUE}?${NC} Label do pendrive (opcional) []: ")" PENDRIVE_LABEL
        PENDRIVE_LABEL=$(printf '%s' "$PENDRIVE_LABEL" | tr -cd '[:alnum:]._ -')
        
        echo
        print_info "Configuração:"
        echo "  Mount point: $MOUNT_POINT"
        [ -n "$PENDRIVE_LABEL" ] && echo "  Label: $PENDRIVE_LABEL"
        echo
    fi
    
    # ---------------------
    # Step 4: Instalação
    # ---------------------
    print_step "Instalando..."
    
    # Permissions
    run chmod +x "$BIN_PATH"
    run chmod +x "$LIB_DIR"/*.sh
    print_success "Permissões ajustadas"
    
    # Config dir
    run mkdir -p "$CONFIG_DIR"
    
    # Write config
    if ! $CHECK_ONLY && ! $DRY_RUN; then
        printf '# usb-driver configuration\nMOUNT_POINT="%s"\nPENDRIVE_LABEL="%s"\n' \
            "$MOUNT_POINT" "$PENDRIVE_LABEL" > "$CONFIG_FILE"
        print_success "Configuração salva em $CONFIG_FILE"
    elif $DRY_RUN; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Criar config em $CONFIG_FILE"
    fi
    
    # Symlink
    if [ -L "$SYMLINK" ]; then
        print_success "Symlink já existe"
    elif [ -e "$SYMLINK" ]; then
        print_warn "Arquivo existe em $SYMLINK (não é symlink)"
    else
        if $CHECK_ONLY; then
            print_info "[CHECK] Symlink seria criado: $SYMLINK"
        else
            run sudo ln -s "$BIN_PATH" "$SYMLINK"
            print_success "Symlink criado: $SYMLINK"
        fi
    fi
    
    # ---------------------
    # Done
    # ---------------------
    echo
    if $CHECK_ONLY; then
        print_success "Verificação concluída — nenhum problema encontrado"
    elif $DRY_RUN; then
        print_success "Simulação concluída"
    else
        echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║     Instalação concluída! 🎉         ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
        echo
        echo "Uso:"
        echo "  usb-driver up       # Monta o pendrive"
        echo "  usb-driver down     # Desmonta"
        echo "  usb-driver status   # Verifica status"
        echo "  usb-driver --simulate up  # Testa sem hardware"
    fi
}

main "$@"
