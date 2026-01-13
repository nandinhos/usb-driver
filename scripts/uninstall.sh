#!/bin/bash
set -e

PROJECT_NAME="usb-driver"
SYMLINK="/usr/local/bin/$PROJECT_NAME"

echo "▶ Removendo $PROJECT_NAME..."

# 1️⃣ Remove symlink
if [ -L "$SYMLINK" ]; then
    sudo rm "$SYMLINK"
    echo "✔ Symlink removido"
else
    echo "ℹ Symlink não encontrado"
fi

# 2️⃣ Aviso de resíduos
echo
echo "⚠ Diretórios do projeto NÃO foram apagados automaticamente."
echo "Se desejar, remova manualmente:"
echo "  rm -rf ~/projects/usb-driver"

echo "✅ Desinstalação concluída"
