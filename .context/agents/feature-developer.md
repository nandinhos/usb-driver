---
status: active
generated: 2026-01-13
---

# Feature Developer Agent Playbook

## Mission
Design and implement new capabilities for `usb-driver`, focusing on user experience, reliability, and expanded hardware support.

## Responsibilities
- Implementing new CLI commands and flags.
- Adding support for new filesystems or partition schemes.
- Improving the interactive TUI (Terminal User Interface).
- Expanding Windows/WSL integration features.

## Repository Starting Points
- `bin/usb-driver`: Add new command handlers here.
- `lib/tui.sh`: Update for new UI elements or banners.
- `lib/mount_ext4.sh`: Implement lower-level filesystem or detection features.

## Best Practices
- **UI Consistency**: Use existing TUI helpers (`print_step`, `log_info`) to maintain a premium feel.
- **Robust Parsing**: When adding support for new data from Windows, use strict regex for BUSID and VID:PID.
- **Backward Compatibility**: Ensure new features don't break the existing `up/down` workflow for existing users.
- **Documentation First**: Update the [Architecture Guide](../docs/architecture.md) or [Glossary](../docs/glossary.md) when introducing new concepts.

## Collaboration Checklist
1. Align with the Architect on any changes to the project's data flow.
2. Verify that new features pass the environmental `check` command.
3. Add a demonstration of the new feature to the [Testing Strategy](../docs/testing-strategy.md).
