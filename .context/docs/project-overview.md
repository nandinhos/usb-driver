# usb-driver: Project Overview

## Summary

The `usb-driver` (formerly `bkp-pendrive`) is a specialized CLI tool designed to simplify USB storage management in **WSL2** environments. It addresses the complexity of attaching, detecting, and mounting physical USB drives (formatted in EXT4, NTFS, vfat, or exfat) that are physically connected to the Windows host but needed within a Linux distribution.

## Architecture

The project follows a modular bash-scripting architecture:

- **Main Entrypoint (`bin/usb-driver`)**: Orchestrates the entire flow, from user input to final mounting.
- **Support Libraries (`lib/`)**:
  - `mount_ext4.sh`: Core logic for device detection using `sysfs`, safety checks to prevent mounting system drives, and filesystem-specific mount commands.
  - `usbipd.sh`: Bridge to the Windows `usbipd-win` utility.
  - `checks.sh`: Environmental validation (WSL version, required packages).
  - `tui.sh` & `logging.sh`: User interface and logging utilities.
- **Install/Uninstall Scripts (`scripts/`)**: Automate symlinking and configuration creation.

## Key Components

1. **Semi-Automated Attachment**: Uses `usbipd-win` to bridge USB devices. Includes a "UAC Promotion" trick to request Admin privileges on the fly in Windows.
2. **Device Pinning (VID:PID)**: Instead of relying on volatile device nodes (like `/dev/sdg`), it tracks devices via Vendor ID and Product ID to ensure the correct device is mounted after the attach process.
3. **Safety Engine (`is_safe_device`)**: Prevents accidental data loss by blacklisting system mount points (`/boot`, `/etc`, etc.) and internal Windows partitions (labels like `SystemReserved` or `Recovery`).
4. **Multi-Filesystem Support**: Transparently handles mounting requirements for EXT4, NTFS (via `ntfs-3g`), FAT32, and exFAT.

---
*Synthesized via semantic analysis of core project files.*
