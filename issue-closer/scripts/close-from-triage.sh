#!/usr/bin/env bash
#
# close-from-triage.sh - Close issues based on triage data analysis
#
# Usage:
#   ./close-from-triage.sh owner/repo triage-data.json
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

echo "Interactive issue closer using triage data"
echo "=========================================="
echo ""

# Find low-priority stale issues (low urgency + importance, old age)
echo "Finding candidates for closure..."
CANDIDATES=$(jq -r '.issues[] | select(
  .scores.urgency != null and .scores.urgency <= 2 and
  .scores.importance != null and .scores.importance <= 2 and
  .age_days > 90
) | "\(.number)\t\(.title)\t(age: \(.age_days)d, importance: \(.scores.importance), urgency: \(.scores.urgency))"' "$TRIAGE_FILE")

if [[ -z "$CANDIDATES" ]]; then
    echo "No candidates found for closure based on triage scores."
    exit 0
fi

echo "$CANDIDATES"
echo ""
echo "Review these issues and close them manually if appropriate:"
echo ""

while IFS=$'\t' read -r number title info; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Issue #$number: $title"
    echo "$info"
    echo ""
    
    gh issue view "$number" --repo "$REPO" 2>/dev/null || echo "(Could not fetch issue details)"
    echo ""
    
    read -p "Close this issue? (y/n/s=skip all/v=view in browser): " -n 1 -r
    echo ""
    
    case $REPLY in
        y|Y)
            read -p "Enter closing reason: " reason
            if [[ -n "$reason" ]]; then
                gh issue close "$number" --repo "$REPO" --comment "$reason"
                echo "✓ Closed #$number"
            else
                echo "Skipped (no reason provided)"
            fi
            ;;
        s|S)
            echo "Skipping remaining issues"
            break
            ;;
        v|V)
            gh issue view "$number" --repo "$REPO" --web
            ;;
        *)
            echo "Skipped"
            ;;
    esac
    echo ""
done <<< "$CANDIDATES"

echo "Done!"
