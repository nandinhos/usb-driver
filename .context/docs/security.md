# Security & Compliance

## Privileged Operations

The `usb-driver` tool requires elevated privileges for several operations:
- **Windows side**: `usbipd bind` requires Administrator privileges to register drivers. We use PowerShell's `RunAs` verb to request this dynamically.
- **Linux side**: `mount` and `umount` commands require `sudo`. Users should be in the `sudoers` group.

## Data Safety Guardrails

To prevent data loss or system instability, the following security measures are implemented:

- **is_safe_device**: A core validation function in `lib/mount_ext4.sh` that prevents the tool from attempting to mount system partitions (e.g., `/`, `/boot`) or the host Windows C: drive.
- **Read-only Fallbacks**: Filesystems are checked before mounting. NTFS is preferred via `ntfs-3g` but may fallback to RO if drivers are missing.
- **Safe Umount**: The `down` command executes `sync` before unmounting to ensure all pending write operations are committed to the hardware.

## Secret Management

- This project does **not** store sensitive data or secrets.
- Integration with Windows is strictly via command-line arguments to the `usbipd.exe` binary.

## Licensing

Licensed under the **MIT License**. Third-party dependencies (`usbipd-win`, `ntfs-3g`) are owned by their respective maintainers and are governed by their own licensing terms.
