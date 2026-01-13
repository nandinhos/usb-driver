#!/bin/bash
# scripts/test.sh - Run all bats tests
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🧪 Running usb-driver test suite..."
echo

# Run all tests
bats "$PROJECT_ROOT/tests/"*.bats

echo
echo "✅ All tests passed!"
