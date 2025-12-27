#!/usr/bin/env bash
#
# fetch-issues.sh - Fetch GitHub issues and save as JSON for analysis
#
# Usage:
#   ./fetch-issues.sh [owner/repo] [--limit N] [--output FILE]
#
# Output:
#   Saves JSON to ./triage-data.json (or specified file)
#   Opens viewer in browser if --view flag is passed
#

set -euo pipefail

LIMIT=50
REPO=""
OUTPUT="triage-data.json"
VIEW=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT="$2"
            shift 2
            ;;
        --view|-v)
            VIEW=true
            shift
            ;;
        *)
            REPO="$1"
            shift
            ;;
    esac
done

# Determine repo name for metadata
if [[ -n "$REPO" ]]; then
    REPO_NAME="$REPO"
    API_URL="https://api.github.com/repos/$REPO/issues?state=open&per_page=$LIMIT"
else
    # Try to get from git remote
    REPO_NAME=$(git remote get-url origin 2>/dev/null | sed 's/.*github.com[:/]\(.*\)\.git/\1/' | sed 's/.*github.com[:/]\(.*\)/\1/' || echo "unknown")
    API_URL="https://api.github.com/repos/$REPO_NAME/issues?state=open&per_page=$LIMIT"
fi

echo "Fetching issues from $REPO_NAME..." >&2

# Fetch and transform
curl -s "$API_URL" | jq --arg repo "$REPO_NAME" --arg generated "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
def days_ago:
    ((now - (. | fromdateiso8601)) / 86400) | floor;

{
    metadata: {
        repository: $repo,
        generated: $generated,
        total_issues: ([.[] | select(.pull_request == null)] | length)
    },
    issues: [.[] | select(.pull_request == null) | {
        number,
        title,
        body: (.body // ""),
        body_preview: (.body // "" | .[0:500]),
        labels: [.labels[] | {name: .name, color: .color}],
        label_names: [.labels[].name],
        created_at: .created_at,
        updated_at: .updated_at,
        age_days: (.created_at | days_ago),
        days_since_update: (.updated_at | days_ago),
        comment_count: .comments,
        is_assigned: ((.assignees | length) > 0),
        assignees: [.assignees[].login],
        milestone: (.milestone.title // null),
        url: .html_url,
        user: .user.login,
        # Placeholder scores for LLM to fill in
        scores: {
            delegation: null,
            importance: null,
            urgency: null,
            clarity: null,
            effort: null,
            priority: null
        },
        analysis: null
    }]
}' > "$OUTPUT"

echo "Saved $(jq '.issues | length' "$OUTPUT") issues to $OUTPUT" >&2

# Open viewer if requested
if [[ "$VIEW" == true ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    VIEWER="$SCRIPT_DIR/../viewer.html"
    if [[ -f "$VIEWER" ]]; then
        # Copy data next to viewer for loading
        cp "$OUTPUT" "$SCRIPT_DIR/../triage-data.json"
        echo "Opening viewer..." >&2
        open "$VIEWER" 2>/dev/null || xdg-open "$VIEWER" 2>/dev/null || echo "Open $VIEWER in your browser" >&2
    else
        echo "Viewer not found at $VIEWER" >&2
    fi
fi
