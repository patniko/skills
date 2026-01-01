#!/usr/bin/env bash
#
# sync-labels.sh - Create standard labels in a GitHub repository
#
# Usage:
#   ./sync-labels.sh --repo owner/repo
#   ./sync-labels.sh --repo owner/repo --dry-run
#

set -euo pipefail

REPO=""
DRY_RUN=false

# Standard label definitions
LABELS='[
    {"name": "priority: critical", "color": "b60205", "description": "Must be addressed immediately"},
    {"name": "priority: high", "color": "d93f0b", "description": "Should be addressed soon"},
    {"name": "priority: medium", "color": "fbca04", "description": "Normal priority"},
    {"name": "priority: low", "color": "0e8a16", "description": "Nice to have"},
    {"name": "effort: trivial", "color": "c5def5", "description": "< 30 minutes"},
    {"name": "effort: small", "color": "bfd4f2", "description": "A few hours"},
    {"name": "effort: medium", "color": "d4c5f9", "description": "A day or two"},
    {"name": "effort: large", "color": "f9d0c4", "description": "A week or more"},
    {"name": "effort: epic", "color": "e99695", "description": "Needs breakdown"},
    {"name": "ai-ready", "color": "0052cc", "description": "Ready for AI coding agent"},
    {"name": "ai-assisted", "color": "006b75", "description": "AI can help but needs human oversight"},
    {"name": "needs-human", "color": "d73a4a", "description": "Requires human judgment/decisions"},
    {"name": "good first issue", "color": "7057ff", "description": "Good for newcomers"},
    {"name": "needs-triage", "color": "ededed", "description": "Needs initial triage"},
    {"name": "stale", "color": "ffffff", "description": "No recent activity"},
    {"name": "duplicate", "color": "cfd3d7", "description": "Duplicate of another issue"},
    {"name": "invalid", "color": "e4e669", "description": "Not a valid issue"},
    {"name": "wontfix", "color": "ffffff", "description": "Will not be addressed"}
]'

usage() {
    echo "Usage: $0 --repo OWNER/REPO [options]"
    echo ""
    echo "Options:"
    echo "  --repo      Repository in owner/repo format (required)"
    echo "  --dry-run   Preview without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 --repo myorg/myrepo"
    echo "  $0 --repo myorg/myrepo --dry-run"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [[ -z "$REPO" ]]; then
    echo "Error: --repo is required"
    usage
fi

echo "Syncing standard labels to $REPO"
echo ""

# Get existing labels
EXISTING=$(gh label list --repo "$REPO" --json name --jq '.[].name' 2>/dev/null || echo "")

# Process each label
echo "$LABELS" | jq -c '.[]' | while read -r label; do
    NAME=$(echo "$label" | jq -r '.name')
    COLOR=$(echo "$label" | jq -r '.color')
    DESC=$(echo "$label" | jq -r '.description')
    
    # Check if label exists
    if echo "$EXISTING" | grep -q "^${NAME}$"; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "[SKIP] $NAME (already exists)"
        else
            # Update existing label
            gh label edit "$NAME" --repo "$REPO" --color "$COLOR" --description "$DESC" 2>/dev/null && \
                echo "[UPDATE] $NAME" || echo "[SKIP] $NAME (no changes needed)"
        fi
    else
        if [[ "$DRY_RUN" == true ]]; then
            echo "[CREATE] $NAME (#$COLOR) - $DESC"
        else
            gh label create "$NAME" --repo "$REPO" --color "$COLOR" --description "$DESC" && \
                echo "[CREATE] $NAME" || echo "[FAIL] $NAME"
        fi
    fi
done

echo ""
echo "Done. Label sync complete for $REPO"
