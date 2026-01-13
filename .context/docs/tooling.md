# Tooling & Productivity Guide

This project relies on a specific set of tools and automation to facilitate the bridge between Windows (Host) and WSL2 (Guest).

## Required Tooling

- **usbipd-win**: Essential Windows-side utility to export USB devices to WSL.
- **PowerShell 5.1+**: Used for orchestration and UAC (User Account Control) elevation requests.
- **ntfs-3g**: Linux driver for full read/write support on NTFS partitions.
- **lsblk & findmnt**: Standard Linux utilities for partition discovery and mount verifying.

## Project Automation

### Installation Wizard
The `./scripts/install.sh` script automates the environment setup:
- Verifies WSL version compatibility.
- Validates `usbipd-win` installation on the Windows side.
- Configures default mount paths and symlinks `/usr/local/bin/usb-driver`.

### Task Workflow
Use the main `usb-driver` script for daily development loops:
- `usb-driver up`: Connects and mounts.
- `usb-driver down`: Safely unmounts and detaches.
- `usb-driver status`: Fast visual check of mounted devices.

## Productivity Tips

- **Custom Mount Paths**: Edit `~/.config/usb-driver/config` to change `MOUNT_POINT`.
- **Simulation Mode**: Use `usb-driver --simulate up` to test the logic without having physical hardware available.
- **UAC Bypass Tip**: If you authorize a device once with `usb-driver up` (which triggers `usbipd bind`), subsequent attaches for that same device won't require the pop-up until the device is physically unplugged or the Windows service restarts.
