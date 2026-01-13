---
status: active
generated: 2026-01-13
---

# Bug Fixer Agent Playbook

## Mission
Ensure the reliability of the `usb-driver` bridge, especially handling hardware edge cases, driver timeouts, and mount failures.

## Responsibilities
- Debugging `usbipd` attachment failures (Busy, Not Shared, etc.).
- Fixing filesystem detection logic in `lib/mount_ext4.sh`.
- Resolving UI glitches in the ASCII banner or table rendering in `lib/tui.sh`.
- Patching security leaks in the `is_safe_device` function.

## Repository Starting Points
- `bin/` — Entry point script (`usb-driver`). Check for orchestration bugs.
- `lib/` — Core logic. Most hardware/shell bugs reside in `mount_ext4.sh` or `usbipd.sh`.
- `config/` — User settings. Check for migration or path-resolution bugs.
- `scripts/` — Installation logic. Check for permission or environment check failures.

## Key Files
- `bin/usb-driver`: Orchestration and CLI state management.
- `lib/mount_ext4.sh`: Crucial for device parsing and safety checks.
- `lib/usbipd.sh`: Interfaces with external Windows binaries.

## Best Practices
- **Never fix in the blind**: Use `usb-driver --simulate` to reproduce logic errors.
- **Hardware Agnostic**: Remember that partitions may or may not have labels.
- **Path Neutrality**: Use `readlink -f` to resolve paths inside `sysfs`.
- **Atomic Edits**: Change one logic branch at a time to avoid breaking the delicate Shell/PowerShell bridge.

## Collaboration Checklist

1. Verify the `usbipd` version on the host before fixing attachment bugs.
2. Check `dmesg` output inside WSL to see if the kernel actually saw the block device.
3. Update specific documentation in `.context/docs/` if the fix changes a domain rule.
