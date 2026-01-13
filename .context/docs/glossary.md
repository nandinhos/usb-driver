# Glossary & Domain Concepts

## Core Terms

- **WSL2 (Windows Subsystem for Linux)**: The virtualization environment where the Linux distribution runs.
- **usbipd-win**: The tool responsible for "exporting" local Windows USB devices so they can be "imported" by the Linux kernel.
- **Bind**: the process of registering a USB device with the `usbipd` driver on Windows. Often requires Admin privileges.
- **Attach**: The process of connecting a "Bound" device to the WSL2 instance.
- **Detach**: Returning the device back to Windows control.
- **VID:PID**: Vendor ID and Product ID. A unique pair for every USB hardware model, used in this project for "pinning" a device to prevent node-swap errors.
- **Mount Point**: The directory in Linux where the USB storage contents appear (default: `/mnt/usb-driver`).

## Acronyms & Abbreviations

- **UAC**: User Account Control (the Windows Admin prompt).
- **EXT4**: Fourth Extended Filesystem (native Linux fs).
- **NTFS**: New Technology File System (native Windows fs).
- **FS**: Filesystem.
- **BUSID**: The hardware address of a USB device on the host (e.g., `2-4`).

## Personas / Actors

- **Developer**: Wants to access Linux-formatted drives (EXT4) for backups or data transfer without leaving the WSL terminal.
- **SysAdmin**: Needs to perform low-level partition management or disk checks using Linux tools on hardware connected to Windows laptops.

## Domain Rules & Invariants

- **Persistence**: Mounts do NOT persist across WSL restarts. They must be re-initialized with `usb-driver up`.
- **Exclusivity**: A device attached to WSL is hidden from Windows until detached.
- **Safety First**: Any partition detected as potentially part of the host system must be ignored by the mounting logic.
