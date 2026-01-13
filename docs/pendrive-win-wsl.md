# 📘 Documento Executivo

## Projeto **usb-driver**

**Autor:** Nando Dev
**Versão:** 1.1.0 (em construção)
**Plataforma-alvo:** Windows 11 + WSL2
**Público:** Desenvolvedores, DevOps, SREs, usuários Linux em migração para Windows

---

## 1. Visão Geral do Projeto

O **usb-driver** é uma ferramenta de automação desenvolvida para permitir o **uso seguro, simples e padronizado de pendrives formatados em EXT4** no ambiente **Windows 11**, através do **WSL2**.

O projeto nasceu da necessidade real de desenvolvedores que:

* Migraram do Linux para Windows
* Possuem **backups, projetos e dados críticos em EXT4**
* Não desejam (ou não podem) reformatar seus dispositivos
* Precisam de um fluxo **confiável, repetível e seguro**, sem etapas manuais complexas

O foco do projeto **não é apenas montar um pendrive**, mas **criar um fluxo de trabalho confiável para backup, resgate e uso contínuo de dados EXT4 no WSL**.

---

## 2. Problema que o Projeto Resolve

### 2.1 Limitações do Windows

* O Windows **não reconhece EXT4 nativamente**
* Pendrives EXT4 **não aparecem como discos** no Windows
* O Explorer não consegue acessar EXT4
* Soluções de terceiros são instáveis ou invasivas

### 2.2 Limitações do WSL

* O WSL **não acessa USBs diretamente**
* É necessário utilizar `usbipd`, com vários comandos manuais
* Alto risco de erro humano:

  * Montar dispositivo errado
  * Escrever em pasta local achando que é o pendrive
  * Esquecer de desmontar corretamente

### 2.3 Dor Real do Desenvolvedor

* Processo repetitivo
* Pouca padronização
* Documentação espalhada
* Falta de automação segura

---

## 3. Objetivo do Projeto

O **usb-driver** foi projetado para:

✔ Automatizar o acesso a pendrives EXT4 no WSL
✔ Eliminar etapas manuais perigosas
✔ Padronizar o fluxo de montagem/desmontagem
✔ Reduzir risco de perda de dados
✔ Facilitar a migração Linux → Windows
✔ Ser simples o suficiente para uso diário
✔ Ser robusto o suficiente para backups críticos

---

## 4. Princípios de Design

O projeto segue princípios claros:

### 4.1 Segurança em Primeiro Lugar

* Um pendrive por vez
* Verificação explícita de montagem
* Falhas interrompem o processo (`fail-fast`)
* Sem automount silencioso

### 4.2 Simplicidade Operacional

* Um único comando:

  ```bash
  usb-driver up
  ```
* Sem necessidade de memorizar:

  * `usbipd list`
  * `attach`
  * `lsblk`
  * `mount`

### 4.3 Transparência Total

* Logs claros
* Mensagens explicativas
* Erros sempre contextualizados

### 4.4 Idempotência

* Reexecutar comandos não quebra o sistema
* Bind e attach seguros
* Mount protegido contra duplicação

---

## 5. Arquitetura da Solução

### 5.1 Camadas

```
┌─────────────────────────────┐
│ Usuário (CLI usb-driver)  │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│ WSL (Linux Scripts)          │
│ - Detecta EXT4               │
│ - Monta / desmonta           │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│ Windows (PowerShell)         │
│ - usbipd bind / attach       │
└───────────────┬─────────────┘
                │
┌───────────────▼─────────────┐
│ Pendrive EXT4                │
└─────────────────────────────┘
```

---

## 6. Fluxo Operacional

### 6.1 Subir (Montar)

```bash
usb-driver up
```

1. Windows:

   * Valida `usbipd`
   * Detecta 1 USB
   * Executa `bind` e `attach`
2. WSL:

   * Detecta dispositivo EXT4 removível
   * Cria mountpoint
   * Monta e ajusta permissões

### 6.2 Usar

```bash
ls /mnt/usb-bkp
```

Operação normal de leitura e escrita.

### 6.3 Descer (Desmontar)

```bash
usb-driver down
```

1. Desmonta filesystem
2. Remove mountpoint
3. Libera o dispositivo

---

## 7. Requisitos do Sistema

### 7.1 Windows

* Windows 11
* WSL2 habilitado
* PowerShell como Administrador
* `usbipd-win` instalado

```powershell
winget install usbipd
```

### 7.2 WSL

* Ubuntu 20.04+
* Acesso sudo
* `util-linux` (lsblk, mount)

---

## 8. Limitações Conhecidas

* Apenas **1 pendrive por vez**
* EXT4 puro (não NTFS / FAT)
* Windows Explorer não escreve em EXT4
* Requer permissão administrativa no Windows

Essas limitações são **decisões conscientes de design**, não falhas.

---

## 9. Público-Alvo

* Desenvolvedores Linux migrando para Windows
* DevOps / SREs
* Profissionais que mantêm backups EXT4
* Ambientes híbridos Windows + Linux
* Comunidades de tecnologia e open-source

---

## 10. Evoluções Planejadas

* Wizard de instalação
* Modo somente leitura (read-only)
* Detecção por LABEL / UUID
* Logs persistentes
* Integração CI para validação
* Releases versionados

---

## 11. Conclusão

O **usb-driver** não é apenas um conjunto de scripts.

Ele é uma **solução prática para um problema real**, criada a partir de experiência de campo, focada em:

> **Segurança, simplicidade e confiabilidade no uso diário.**

O projeto está aberto à avaliação, contribuição e evolução pela comunidade.

---

📌 **Autor:** Nando Dev
📌 **Propósito:** Facilitar a vida de quem vive entre Linux e Windows
📌 **Status:** Ativo / em evolução

---