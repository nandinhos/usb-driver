# Testing Strategy

Due to the nature of `usb-driver` (direct hardware interaction), automated testing is primarily focused on logic simulation and environment validation.

## Manual Verification (Gold Standard)

The primary way to test is with physical hardware:
1. Plug an EXT4/NTFS/FAT32 pendrive.
2. Run `usb-driver up`.
3. Verify files are accessible at `/mnt/usb-driver/<LABEL>`.
4. Run `usb-driver down` and verify hardware is released to Windows.

## Simulation Mode (`--simulate`)

The `--simulate` flag allows testing the script's decision tree without needing a USB device or sudo privileges:
- Mocked PowerShell responses.
- Simulated `lsblk` data.
- Virtual mount points.

## Environment Health Check

The `usb-driver check` command (powered by `lib/checks.sh`) serves as a diagnostic suite:
- Validates kernel strings for WSL2.
- Checks if `usbipd` is accessible from the Windows PATH.
- Verifies existence of required binaries (`ntfs-3g`, etc.).

## Contribution Checklist

Before submitting changes:
- [ ] Run `usb-driver help` to ensure the banner renders correctly.
- [ ] Run `usb-driver check` to verify the local environment.
- [ ] Test the `up` and `down` flow with at least one physical device.
- [ ] Verify that `usb-driver list` correctly identifies "Shared" vs "Not Shared" states.
