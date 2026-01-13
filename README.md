# usb-driver

<p align="center">
  <img src="img/nando-dev-logo.png" alt="NandoDev Logo" width="200"/>
</p>

<p align="center">
  <strong>🔌 Ferramenta CLI Pro para montar Pendrives e HDs Externos no WSL2</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.9.0-blue?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/platform-WSL2-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/shell-bash-green?style=flat-square" alt="Shell">
  <img src="https://img.shields.io/badge/tests-bats--core-brightgreen?style=flat-square" alt="Tests">
  <img src="https://img.shields.io/badge/lint-shellcheck-brightgreen?style=flat-square" alt="Lint">
</p>

---

## 📋 Sobre

O **usb-driver** resolve um problema comum para desenvolvedores que usam WSL2: montar dispositivos de armazenamento USB (**Pendrives** e **HDs Externos**) formatados em **EXT4**, **NTFS**, **FAT32** ou **exFAT** diretamente no Linux com extrema confiabilidade e facilidade.

### ✨ O que há de novo (v0.7.0 -> v0.9.0)

- ✅ **Qualidade de Código**: 100% validado com `shellcheck`.
- 🏗️ **Arquitetura Sólida**: Constantes e lógica de estado centralizadas.
- 🧪 **Testes Automatizados**: Suite de testes completa com `bats-core`.
- 🛠️ **Modo Verbose**: Flag `-v` para depuração profunda.
- ⚡ **Autocomplete**: Suporte a Bash e Zsh para comandos e BUSIDs.

---

## 🚀 Instalação

### Pré-requisitos

1. **Windows 11** (ou Windows 10 com WSL2)
2. **WSL2** com uma distribuição Linux
3. **usbipd-win** instalado no Windows (`winget install usbipd`)
4. **ntfs-3g** instalado no Linux (`sudo apt install ntfs-3g`)

### Instalação do usb-driver

```bash
git clone https://github.com/nandinhos/bkp-pendrive.git usb-driver
cd usb-driver
./scripts/install.sh
```

---

## 📖 Uso

### Comandos principais

```bash
usb-driver up          # Monta dispositivo (detecção automática)
usb-driver up -s       # Escolhe o dispositivo manualmente
usb-driver down        # Desmonta com menu interativo
usb-driver list        # Lista dispositivos no Windows e WSL
usb-driver status      # Check de montagem atual
usb-driver help        # Manual completo
```

### Opções úteis

- `-v, --verbose`: Mostra logs detalhados de execução.
- `--simulate`: Testa a interface sem tocar no hardware.
- `--force`: Força a desmontagem mesmo se o dispositivo estiver ocupado.

---

## 🧪 Desenvolvimento e Qualidade

Para garantir a estabilidade, o projeto conta com ferramentas de CI/CD locais:

```bash
# Rodar testes de unidade (12+ testes)
./scripts/test.sh

# Validar sintaxe e boas práticas (shellcheck)
./scripts/lint.sh
```

---

## 🏗️ Estrutura do Projeto

```
usb-driver/
├── bin/
│   └── usb-driver        # CLI principal v0.9.0
├── lib/
│   ├── constants.sh      # Centralização de configurações e versão
│   ├── logging.sh        # UI e cores (log_info, log_debug, etc)
│   ├── usbipd.sh         # Bridge com Windows
│   └── mount_ext4.sh     # Core de montagem
├── tests/                # Suite de testes bats-core
├── completions/          # Scripts de autocompletar (bash/zsh)
├── scripts/
│   ├── test.sh           # Runner de testes
│   └── lint.sh           # Runner de análise estática
└── CHANGELOG.md          # Histórico detalhado de versões
```

---

## 🤝 Contribuindo

Contribuições são bem-vindas! O projeto agora segue padrões rigorosos de qualidade. Certifique-se de que `./scripts/test.sh` e `./scripts/lint.sh` passem antes de abrir um PR.

---

## 📄 Licença

Este projeto está sob a licença MIT. 

---

## 👤 Autor

Desenvolvido por **NandoDev** com ❤️ para a comunidade WSL/Linux.

<p align="center">
  <sub>⭐ Se este projeto te ajudou, deixe uma estrela!</sub>
</p>
