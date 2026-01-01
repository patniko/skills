#!/usr/bin/env bash
#
# request-info.sh - Comment on unclear issues requesting more information
#
# Usage:
#   ./request-info.sh owner/repo triage-data.json
#

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 owner/repo triage-data.json" >&2
    exit 1
fi

REPO="$1"
TRIAGE_FILE="$2"

if [[ ! -f "$TRIAGE_FILE" ]]; then
    echo "Error: Triage file not found: $TRIAGE_FILE" >&2
    exit 1
fi

TEMPLATE="Thanks for reporting this issue! To help us investigate, could you provide:

1. **Steps to reproduce**: Detailed steps to recreate the issue
2. **Expected behavior**: What should happen
3. **Actual behavior**: What actually happens  
4. **Environment**: OS, version, configuration details
5. **Logs/Screenshots**: Any relevant error messages or screenshots

If we don't receive this information within 14 days, we may close this issue as stale."

echo "Finding unclear issues (low clarity score)..."
UNCLEAR=$(jq -r '.issues[] | select(
  .scores.clarity != null and .scores.clarity <= 2
) | "\(.number)\t\(.title)\t(clarity: \(.scores.clarity))"' "$TRIAGE_FILE")

if [[ -z "$UNCLEAR" ]]; then
    echo "No unclear issues found."
    exit 0
fi

echo "$UNCLEAR"
echo ""
echo "These issues have low clarity scores and may benefit from requesting more info."
echo ""

read -p "Add info request comment to these issues? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

echo "$UNCLEAR" | while IFS=$'\t' read -r number title info; do
    echo -n "Commenting on #$number... "
    if gh issue comment "$number" --repo "$REPO" --body "$TEMPLATE" 2>/dev/null; then
        echo "✓"
        # Add needs-info label if possible
        gh issue edit "$number" --add-label "needs-info" --repo "$REPO" 2>/dev/null || true
    else
        echo "✗"
    fi
done

echo ""
echo "Done!"
