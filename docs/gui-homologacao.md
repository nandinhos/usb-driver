# Homologação — USB Driver GUI (Electron + WSL2)

## 1. Privilégio Mínimo no WSL2

Para que a interface gráfica monte e desmonte dispositivos sem travar aguardando senha no `sudo`:

```bash
./scripts/setup-sudoers.sh --dry-run   # Inspecionar regra gerada
./scripts/setup-sudoers.sh             # Validar com visudo e instalar em /etc/sudoers.d/usb-driver
```

A regra restringe o `NOPASSWD` exclusivamente a `blkid`, `mkdir`, `rmdir`, `mount`, `umount` e `ntfs-3g` operando sobre `/dev/sd*` e `/mnt/usb-driver/*`.

## 2. Compilação e Empacotamento Windows (`.exe`)

Dentro de `gui/`:

```bash
npm install
npm run build        # Typecheck + Vite + Main Process
npm run test:bridge  # Testes unitários dos validadores IPC
npm run dist:win     # Gera instalador NSIS e executável portátil em gui/release/
```

## 3. Checklist de Homologação

1. Abrir a aplicação com **Simular** ativado: confirmar que `HealthBanner`, `WslDeviceCard` e `WindowsDeviceCard` exibem os dispositivos simulados e executam montar/ejetar sem erros.
2. Conectar pendrive real no Windows (`NotShared`): clicar em **Compartilhar (UAC)** e aprovar a elevação única do `usbipd bind --force`.
3. Clicar em **Montar no WSL**: validar montagem em `/mnt/usb-driver/<LABEL>` e abertura da pasta no Explorer (`\\wsl.localhost\<distro>\mnt\usb-driver\...`).
4. Clicar em **Ejetar com Segurança**: validar `umount` + `usbipd detach`.
