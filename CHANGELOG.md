# Changelog

## [0.2.0] - 2026-01-12

### ✨ Novas Funcionalidades
- **Suporte a HD Externo:** Adicionada capacidade de detectar e montar HDs Externos automaticamente (incluindo dispositivos UAS/SCSI).
  - *Nota:* Recomendado ter apenas um HD externo conectado por vez para evitar ambiguidades na auto-detecção.
- **Detecção de Dependências:** Instalação interativa do driver `ntfs-3g` quando um dispositivo NTFS é detectado e o driver não está presente.
- **Melhorias de Performance:** Aumento do timeout de detecção para suportar discos rígidos mecânicos que demoram a inicializar.

### 🐛 Correções
- Correção na string de busca do `usbipd` para incluir dispositivos "UAS" e "SCSI".
- **[CRÍTICO]** Corrigido bug que permitia montar partições do sistema quando nenhum USB estava conectado. Agora o script verifica se o dispositivo já está montado antes de prosseguir.

---

## [0.1.0] - 2026-01-12
- Lançamento inicial com suporte a pendrives EXT4, NTFS, FAT32 e exFAT.
- Auto-attach via usbipd-win.
- Instalador interativo e CLI `up`/`down`.
