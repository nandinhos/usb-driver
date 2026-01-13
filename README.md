# usb-driver

<p align="center">
  <img src="img/nando-dev-logo.png" alt="NandoDev Logo" width="200"/>
</p>

<p align="center">
  <strong>🔌 Ferramenta CLI para montar Pendrives e HDs Externos no WSL2</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-WSL2-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/shell-bash-green?style=flat-square" alt="Shell">
  <img src="https://img.shields.io/badge/license-MIT-yellow?style=flat-square" alt="License">
</p>

---

## 📋 Sobre

O **usb-driver** resolve um problema comum para desenvolvedores que usam WSL2: montar dispositivos de armazenamento USB (**Pendrives** e **HDs Externos**) formatados em **EXT4**, **NTFS**, **FAT32** ou **exFAT** diretamente no Linux, sem precisar acessar via `/mnt/c/`.

### ✨ Funcionalidades

- 🔄 **Semi-Auto-attach** via `usbipd-win` - anexa o USB ao WSL mediante autorização do usuário no PowerShell como Admin
- 📁 **Multi-filesystem** - suporta EXT4, NTFS, FAT32, exFAT
- 🎨 **Interface colorida** - output amigável com cores ANSI
- ⚡ **Simples de usar** - apenas `usb-driver up` e `down`
- 🧪 **Modo simulação** - teste sem hardware com `--simulate`

---

## 🚀 Instalação

### Pré-requisitos

1. **Windows 11** (ou Windows 10 com WSL2)
2. **WSL2** com uma distribuição Linux (Ubuntu recomendado)
3. **usbipd-win** instalado no Windows
4. **NTFS-3G** instalado no Linux (para suporte a escrita em discos NTFS)

#### Instalar usbipd-win (PowerShell como Admin):
```powershell
winget install usbipd
```

#### Instalar drivers NTFS (no Linux usando WSL):
Para garantir suporte a escrita em discos NTFS, instale o driver apropriado:
```bash
sudo apt update && sudo apt install ntfs-3g
```

### Instalação do usb-driver

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/usb-driver.git
cd usb-driver

# Execute o instalador
./scripts/install.sh
```

O instalador irá:
- ✅ Verificar ambiente WSL
- ✅ Validar instalação do usbipd-win
- ✅ Configurar mount point
- ✅ Criar symlink em `/usr/local/bin`

---

## 📖 Uso

### Comandos básicos

```bash
# Montar dispositivo
usb-driver up

# Desmontar dispositivo
usb-driver down

# Verificar status
usb-driver status

# Ajuda
usb-driver help
```

### Modo simulação (para testes)

```bash
usb-driver --simulate up
usb-driver --simulate down
```

### Primeiro uso (Semi-automático)

Para conectar um dispositivo USB (Pendrive ou HD Externo) ao WSL2 via `usbipd`, é necessário permissão de Administrador no Windows **apenas na primeira vez** (para o comando `bind`).

O script tentará automatizar tudo, mas se precisar de permissão, ele exibirá o comando exato para você copiar e colar:

```
[WARN] Dispositivo precisa ser registrado (bind) no Windows.

==========================================
  Execute no PowerShell como ADMIN:

    usbipd bind --busid 2-3 (ou usbipd bind --busid <BUSID>)


  Após executar, pressione ENTER...
==========================================
```

Depois do bind inicial, o dispositivo funcionará automaticamente.

> **Nota:** Recomenda-se manter apenas **um** dispositivo de armazenamento externo conectado por vez para garantir a detecção automática correta.

---

## ⚙️ Configuração

A configuração é salva em `~/.config/usb-driver/config`:

```bash
MOUNT_POINT="/mnt/usb-driver"
PENDRIVE_LABEL="MeuDispositivo"
```

### Reinstalar/Reconfigurar

```bash
cd ~/projects/usb-driver
./scripts/install.sh
```

---

## 🏗️ Estrutura do Projeto

```
usb-driver/
├── bin/
│   └── usb-driver      # CLI principal
├── lib/
│   ├── logging.sh        # Funções de log colorido
│   ├── tui.sh            # Helpers de interface
│   ├── checks.sh         # Validações de ambiente
│   ├── usbipd.sh         # Integração com usbipd-win
│   └── mount_ext4.sh     # Lógica de mount/unmount
├── scripts/
│   ├── install.sh        # Wizard de instalação
│   └── uninstall.sh      # Desinstalador
├── config/
│   └── usb-driver.conf # Configuração padrão
└── docs/
    └── README.md
```

---

## 🔧 Requisitos Técnicos

| Componente | Versão Mínima |
|------------|---------------|
| Windows | 10 (build 19041+) ou 11 |
| WSL | 2.0 |
| usbipd-win | 4.0+ |
| Bash | 4.0+ |

### Ferramentas Linux utilizadas

- `lsblk`, `blkid`, `mount`, `umount`
- `findmnt`, `mountpoint`
- `powershell.exe` (para comunicação com Windows)

---

## 🐛 Troubleshooting

### "Device is not shared"

Execute no PowerShell como Admin:
```powershell
usbipd bind --busid <BUSID>
```

### Pendrive não aparece no WSL

1. Verifique se o pendrive está conectado: `usbipd list`
2. Anexe manualmente: `usbipd attach --wsl --busid <BUSID>`

### Erro de permissão ao montar

O comando `mount` requer sudo. Certifique-se de que seu usuário está no grupo `sudo`.

---

## 🤝 Contribuindo

Contribuições são bem-vindas! 

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👤 Autor

<p align="left">
  <img src="img/nando-dev-logo.png" alt="NandoDev" width="50" style="vertical-align:middle"/>
  <strong>Desenvolvido por NandoDev</strong>
</p>

Desenvolvido com ❤️ para a comunidade WSL/Linux.

---

<p align="center">
  <sub>⭐ Se este projeto te ajudou, deixe uma estrela!</sub>
</p>
