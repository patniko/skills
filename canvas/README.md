# Canvas Skill

Interactive terminal TUI components for AI coding assistants. Spawn calendars, documents, and flight booking interfaces in tmux split panes.

## Quick Start

```bash
# Install dependencies
cd canvas
bun install

# Test calendar display
bun run src/cli.ts show calendar

# Test meeting picker (requires tmux)
bun run src/cli.ts spawn calendar --scenario meeting-picker --config '{
  "calendars": [
    {"name": "Test", "color": "blue", "events": []}
  ]
}'
```

## Features

- **Calendar Canvas**: Display events, pick meeting times across multiple calendars
- **Document Canvas**: Render markdown, select text, highlight diffs
- **Flight Canvas**: Compare flights, select seats with interactive seatmap
- **IPC Communication**: Real-time bidirectional communication between canvas and controller
- **Tmux Integration**: Spawns in split panes without blocking main terminal

## Requirements

- [Bun](https://bun.sh) - JavaScript runtime
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- Terminal with mouse support (most modern terminals)

## Usage in Skills

See [SKILL.md](./SKILL.md) for complete documentation and examples.

## Development

```bash
# Run CLI
bun run src/cli.ts

# Run tests
bun test

# Install new dependencies
bun install <package>
```

## Architecture

```
src/
├── cli.ts              # Command-line interface
├── canvases/           # React/Ink UI components
│   ├── calendar/       # Calendar canvas
│   ├── document/       # Document canvas
│   └── flight/         # Flight canvas
├── scenarios/          # Scenario configurations
│   ├── calendar/       # Calendar scenarios
│   ├── document/       # Document scenarios
│   └── registry.ts     # Scenario registry
├── ipc/                # Unix socket IPC
│   ├── server.ts       # Canvas-side IPC server
│   └── client.ts       # Controller-side IPC client
└── api/                # High-level async API
    └── index.ts        # pickMeetingTime, editDocument, etc.
```

## License

MIT
