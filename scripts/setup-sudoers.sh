#!/usr/bin/env bash
# scripts/setup-sudoers.sh - Configura privilégio mínimo no WSL2 para montagem sem senha interativa
set -euo pipefail

TARGET_FILE="/etc/sudoers.d/usb-driver"
CURRENT_USER="${SUDO_USER:-$USER}"
DRY_RUN=false
REMOVE=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --remove)  REMOVE=true ;;
        --help|-h)
            echo "Uso: ./scripts/setup-sudoers.sh [--dry-run|--remove]"
            exit 0
            ;;
    esac
done

if $REMOVE; then
    if [ -f "$TARGET_FILE" ]; then
        if $DRY_RUN; then
            echo "[DRY-RUN] sudo rm -f $TARGET_FILE"
        else
            sudo rm -f "$TARGET_FILE"
            echo "Regra removida: $TARGET_FILE"
        fi
    else
        echo "Nenhuma regra encontrada em $TARGET_FILE"
    fi
    exit 0
fi

if [ "$CURRENT_USER" = "root" ]; then
    echo "Execute este script como usuário padrão do WSL (não diretamente como root)." >&2
    exit 1
fi

BIN_MOUNT=$(command -v mount)
BIN_UMOUNT=$(command -v umount)
BIN_BLKID=$(command -v blkid)
BIN_MKDIR=$(command -v mkdir)
BIN_RMDIR=$(command -v rmdir)
BIN_NTFS3G=$(command -v ntfs-3g || true)
BIN_EXFAT=$(command -v mount.exfat-fuse || true)

RULE_CONTENT="# Gerado por usb-driver/scripts/setup-sudoers.sh (privilégio mínimo)
${CURRENT_USER} ALL=(root) NOPASSWD: ${BIN_BLKID} -o value -s TYPE /dev/sd*
${CURRENT_USER} ALL=(root) NOPASSWD: ${BIN_MKDIR} -p /mnt/usb-driver/*
${CURRENT_USER} ALL=(root) NOPASSWD: ${BIN_RMDIR} /mnt/usb-driver/*
${CURRENT_USER} ALL=(root) NOPASSWD: ${BIN_MOUNT} /dev/sd* /mnt/usb-driver/*, ${BIN_MOUNT} /dev/sd* /mnt/usb-driver/* -o *
${CURRENT_USER} ALL=(root) NOPASSWD: ${BIN_UMOUNT} /mnt/usb-driver/*, ${BIN_UMOUNT} -f /mnt/usb-driver/*"

if [ -n "$BIN_NTFS3G" ]; then
    RULE_CONTENT="${RULE_CONTENT}
${CURRENT_USER} ALL=(root) NOPASSWD: ${BIN_NTFS3G} /dev/sd* /mnt/usb-driver/*, ${BIN_NTFS3G} /dev/sd* /mnt/usb-driver/* -o *"
fi

if [ -n "$BIN_EXFAT" ]; then
    RULE_CONTENT="${RULE_CONTENT}
${CURRENT_USER} ALL=(root) NOPASSWD: ${BIN_EXFAT} /dev/sd* /mnt/usb-driver/*, ${BIN_EXFAT} /dev/sd* /mnt/usb-driver/* -o *"
fi

if $DRY_RUN; then
    echo "[DRY-RUN] Conteúdo que seria validado e gravado em $TARGET_FILE:"
    echo "$RULE_CONTENT"
    exit 0
fi

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT
printf '%s\n' "$RULE_CONTENT" > "$TMP_FILE"

if ! sudo visudo -cf "$TMP_FILE"; then
    echo "Falha na validação visudo. Abortando sem alterar $TARGET_FILE." >&2
    exit 1
fi

sudo install -m 0440 -o root -g root "$TMP_FILE" "$TARGET_FILE"
echo "Regra de privilégio mínimo instalada com sucesso em $TARGET_FILE"
