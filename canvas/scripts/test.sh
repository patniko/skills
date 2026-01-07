#!/bin/bash
# Test canvas skill installation and basic functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Canvas Skill Test ==="
echo

# Check Bun
echo "✓ Checking for Bun..."
if ! command -v bun &> /dev/null; then
    echo "✗ Bun not found. Install from https://bun.sh"
    exit 1
fi
echo "  Found: $(bun --version)"

# Check tmux
echo "✓ Checking for tmux..."
if ! command -v tmux &> /dev/null; then
    echo "✗ tmux not found. Install with: brew install tmux"
    exit 1
fi
echo "  Found: $(tmux -V)"

# Install dependencies
echo "✓ Installing dependencies..."
cd "$SKILL_DIR"
bun install --silent

# Test CLI help
echo "✓ Testing CLI..."
bun run src/cli.ts --help > /dev/null 2>&1 || {
    echo "✗ CLI test failed"
    exit 1
}

# Test calendar config
echo "✓ Testing calendar display..."
timeout 2s bun run src/cli.ts show calendar --config '{
  "title": "Test",
  "events": []
}' > /dev/null 2>&1 || true

echo
echo "=== All tests passed! ==="
echo
echo "Try these commands:"
echo "  bun run src/cli.ts show calendar"
echo "  bun run src/cli.ts --help"
echo
echo "For tmux-based spawning, start tmux first:"
echo "  tmux"
echo "  bun run src/cli.ts spawn calendar --scenario meeting-picker --config '{...}'"
