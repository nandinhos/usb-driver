# Development Workflow

## Branching & Releases

- **Branching Model**: Trunk-based development with short-lived feature branches.
- **Main Branch**: `dev` for active development, merging into `main` for stable releases.
- **Releases**: Follow Semantic Versioning (SemVer). The `VERSION` file at the root tracks the current project version.

## Local Development Loop

Since this tool interacts directly with hardware and OS-level drivers, local development requires a WSL2 environment.

1. **Modify**: Edit files in `bin/`, `lib/`, or `scripts/`.
2. **Execute Locally**: Call the script using its relative path:
   ```bash
   ./bin/usb-driver up
   ```
3. **Debug**: Use `SIMULATE_MODE=true` or `--simulate` to trace logic without executing PowerShell commands.

## Versioning & Tags

When a new version is ready:
1. Update the `VERSION` file.
2. Update the `VERSION` variable inside `bin/usb-driver` (this is ideally automated or checked during `help`).
3. Commit with the version tag: `git commit -m "v0.6.x: Summary"`.

## Code Standard

- **Bash**: Use `set -e` for fail-fast execution.
- **Modularity**: Business logic must stay in `lib/*.sh`, while `bin/usb-driver` handles user interaction.
- **UI**: Always use the color tokens from `lib/tui.sh` for user-facing messages.
