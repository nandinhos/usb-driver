---
status: active
generated: 2026-01-13
---

# DevOps Specialist Agent Playbook

## Mission
Manage the environment validation, installation lifecycle, and cross-platform dependencies of the `usb-driver` tool.

## Responsibilities
- Maintaining `scripts/install.sh` and `scripts/uninstall.sh`.
- Ensuring `lib/checks.sh` accurately identifies required Windows and Linux binaries.
- Managing versioning and symlink health in `/usr/local/bin`.
- Optimizing PowerShell one-liners used for UAC elevation and driver binding.

## Repository Starting Points
- `scripts/`: Implementation of the installation wizard and cleanup logic.
- `lib/checks.sh`: The gatekeeper for environment requirements.
- `VERSION`: The single source of truth for the project release state.

## Best Practices
- **Non-Destructive Installs**: The installer should never delete user config files unless explicitly requested.
- **Cross-Distro WSL**: Ensure scripts work on Ubuntu, Debian, and other common WSL2 distros.
- **Path Resolution**: Use `readlink -f` to ensure the tool can be executed from anywhere via its symlink.

## Key Project Resources
- [Tooling & Productivity Guide](../docs/tooling.md)
- [Security & Compliance Notes](../docs/security.md)
- [Development Workflow](../docs/development-workflow.md)
