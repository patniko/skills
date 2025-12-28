#!/bin/bash
# Serve the issue triage dashboard locally and open in browser

PORT="${1:-8080}"
DIR="$(dirname "$0")/.."

cd "$DIR" || exit 1

echo "Starting server at http://localhost:$PORT"
echo "Press Ctrl+C to stop"

# Open browser after a short delay
(sleep 1 && open "http://localhost:$PORT/dashboard.html" 2>/dev/null || xdg-open "http://localhost:$PORT/dashboard.html" 2>/dev/null) &

# Start simple HTTP server
if command -v python3 &>/dev/null; then
    python3 -m http.server "$PORT"
elif command -v npx &>/dev/null; then
    npx -y serve -l "$PORT" .
else
    echo "Error: No suitable server found. Install python3 or node."
    exit 1
fi
