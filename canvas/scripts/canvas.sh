#!/bin/bash
# Canvas skill helper script
# Usage: ./scripts/canvas.sh <command> [args...]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SKILL_DIR"

# Check for Bun
if ! command -v bun &> /dev/null; then
    echo "Error: Bun is not installed. Install from https://bun.sh"
    exit 1
fi

# Check for tmux when spawning
if [[ "$1" == "spawn" ]] && ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not installed. Install with: brew install tmux"
    exit 1
fi

# Check if in tmux session when spawning
if [[ "$1" == "spawn" ]] && [ -z "$TMUX" ]; then
    echo "Error: spawn requires running inside a tmux session"
    echo "Start tmux with: tmux"
    exit 1
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    bun install
fi

# Run the CLI
exec bun run src/cli.ts "$@"
