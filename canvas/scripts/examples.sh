#!/bin/bash
# Canvas skill examples and demos

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

cd "$SKILL_DIR"

echo "=== Canvas Skill Examples ==="
echo
echo "Select an example:"
echo "  1) Calendar - Display events"
echo "  2) Calendar - Meeting picker (requires tmux)"
echo "  3) Document - Display markdown"
echo "  4) Document - Edit with selection (requires tmux)"
echo "  5) Flight - Booking interface (requires tmux)"
echo "  q) Quit"
echo
read -p "Enter choice: " choice

case $choice in
    1)
        echo "Displaying calendar with sample events..."
        bun run src/cli.ts show calendar --config '{
          "title": "My Schedule",
          "events": [
            {
              "id": "1",
              "title": "Team Standup",
              "startTime": "2026-01-07T09:00:00",
              "endTime": "2026-01-07T09:30:00",
              "color": "blue"
            },
            {
              "id": "2",
              "title": "Code Review",
              "startTime": "2026-01-07T14:00:00",
              "endTime": "2026-01-07T15:00:00",
              "color": "green"
            }
          ]
        }'
        ;;
    2)
        if [ -z "$TMUX" ]; then
            echo "Error: Meeting picker requires tmux. Start tmux first."
            exit 1
        fi
        echo "Spawning meeting picker..."
        bun run src/cli.ts spawn calendar --scenario meeting-picker --config '{
          "calendars": [
            {
              "name": "Alice",
              "color": "blue",
              "events": [
                {"id": "1", "title": "Standup", "startTime": "2026-01-07T09:00:00", "endTime": "2026-01-07T09:30:00"}
              ]
            },
            {
              "name": "Bob",
              "color": "green",
              "events": [
                {"id": "2", "title": "Meeting", "startTime": "2026-01-07T14:00:00", "endTime": "2026-01-07T15:00:00"}
              ]
            }
          ],
          "slotGranularity": 30
        }'
        ;;
    3)
        echo "Displaying markdown document..."
        bun run src/cli.ts show document --config '{
          "title": "Sample Document",
          "content": "# Welcome to Canvas\n\nThis is a **markdown** document with:\n\n- Bullet points\n- **Bold text**\n- *Italic text*\n\n## Code Example\n\n\`\`\`javascript\nconst hello = \"world\";\n\`\`\`\n\nPress q to close."
        }'
        ;;
    4)
        if [ -z "$TMUX" ]; then
            echo "Error: Document edit requires tmux. Start tmux first."
            exit 1
        fi
        echo "Spawning document editor..."
        bun run src/cli.ts spawn document --scenario edit --config '{
          "title": "Edit Mode",
          "content": "# My Document\n\nClick and drag to select text.\n\nThis is a **sample** document for editing."
        }'
        ;;
    5)
        if [ -z "$TMUX" ]; then
            echo "Error: Flight booking requires tmux. Start tmux first."
            exit 1
        fi
        echo "Spawning flight booking interface..."
        bun run src/cli.ts spawn flight --scenario booking --config '{
          "title": "// FLIGHT_BOOKING //",
          "flights": [
            {
              "id": "ua123",
              "airline": "United Airlines",
              "flightNumber": "UA 123",
              "origin": {
                "code": "SFO",
                "name": "San Francisco Intl",
                "city": "San Francisco",
                "timezone": "PST"
              },
              "destination": {
                "code": "DEN",
                "name": "Denver Intl",
                "city": "Denver",
                "timezone": "MST"
              },
              "departureTime": "2026-01-08T12:55:00-08:00",
              "arrivalTime": "2026-01-08T16:37:00-07:00",
              "duration": 162,
              "price": 34500,
              "currency": "USD",
              "cabinClass": "economy",
              "aircraft": "Boeing 737-800",
              "stops": 0,
              "seatmap": {
                "rows": 20,
                "seatsPerRow": ["A", "B", "C", "D", "E", "F"],
                "aisleAfter": ["C"],
                "unavailable": ["1A", "1B", "1C", "1D", "1E", "1F"],
                "premium": ["2A", "2B", "2C", "2D", "2E", "2F"],
                "occupied": ["3A", "4B", "5C"]
              }
            }
          ]
        }'
        ;;
    q|Q)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
