---
status: active
generated: 2026-01-13
---

# Architect Specialist Agent Playbook

## Mission
Design and maintain the structural integrity of the `usb-driver` system, ensuring modularity between Shell scripts and seamless integration with Windows sub-processes.

## Responsibilities
- Define data structures for configuration and device tracking.
- Design the state machine for device attachment flows (Bind -> Attach -> Mount).
- Ensure backward compatibility for legacy path migrations.
- Guard the "VID:PID Pinning" strategy to ensure robust device addressing.

## Repository Starting Points
- `bin/usb-driver`: Source of command orchestration and release logic.
- `lib/`: Domain libraries. Focus on interface boundaries between `.sh` files.
- `docs/architecture.md`: Reference for system layers and data flows.

## Best Practices
- **Prefer Modularity**: Logic that doesn't strictly require user input belongs in `lib/`.
- **System Parity**: Always consider how a change in the Linux logic affects the assumptions made about the Windows `usbipd` state.
- **Fail-Fast**: Ensure errors in one layer (e.g., attachment) prevent execution of the next layer (e.g., mounting) to avoid data corruption.

## Key Project Resources
- [Architecture Notes](../docs/architecture.md)
- [Data Flow & Integrations](../docs/data-flow.md)
