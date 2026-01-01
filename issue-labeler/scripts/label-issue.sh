#!/usr/bin/env bash
#
# label-issue.sh - Add or remove labels from a GitHub issue
#
# Usage:
#   ./label-issue.sh --repo owner/repo --issue 123 --add "bug"
#   ./label-issue.sh --repo owner/repo --issue 123 --add "bug,priority: high"
#   ./label-issue.sh --repo owner/repo --issue 123 --remove "needs-triage"
#

set -euo pipefail

REPO=""
ISSUE=""
ADD_LABELS=""
REMOVE_LABELS=""
DRY_RUN=false

usage() {
    echo "Usage: $0 --repo OWNER/REPO --issue NUMBER [options]"
    echo ""
    echo "Options:"
    echo "  --repo      Repository in owner/repo format (required)"
    echo "  --issue     Issue number (required)"
    echo "  --add       Comma-separated labels to add"
    echo "  --remove    Comma-separated labels to remove"
    echo "  --dry-run   Preview without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 --repo myorg/myrepo --issue 42 --add 'bug,priority: high'"
    echo "  $0 --repo myorg/myrepo --issue 42 --remove 'needs-triage'"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO="$2"
            shift 2
            ;;
        --issue)
            ISSUE="$2"
            shift 2
            ;;
        --add)
            ADD_LABELS="$2"
            shift 2
            ;;
        --remove)
            REMOVE_LABELS="$2"
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

# Validate required arguments
if [[ -z "$REPO" || -z "$ISSUE" ]]; then
    echo "Error: --repo and --issue are required"
    usage
fi

if [[ -z "$ADD_LABELS" && -z "$REMOVE_LABELS" ]]; then
    echo "Error: At least one of --add or --remove is required"
    usage
fi

echo "Updating labels for issue #$ISSUE in $REPO"

# Process labels to remove
if [[ -n "$REMOVE_LABELS" ]]; then
    IFS=',' read -ra LABELS <<< "$REMOVE_LABELS"
    for LABEL in "${LABELS[@]}"; do
        LABEL=$(echo "$LABEL" | xargs)  # Trim whitespace
        echo "  Removing: $LABEL"
        if [[ "$DRY_RUN" == true ]]; then
            echo "    [DRY RUN] Would run: gh issue edit $ISSUE --repo $REPO --remove-label \"$LABEL\""
        else
            gh issue edit "$ISSUE" --repo "$REPO" --remove-label "$LABEL" 2>/dev/null || \
                echo "    Warning: Could not remove label '$LABEL' (may not exist)"
        fi
    done
fi

# Process labels to add
if [[ -n "$ADD_LABELS" ]]; then
    IFS=',' read -ra LABELS <<< "$ADD_LABELS"
    for LABEL in "${LABELS[@]}"; do
        LABEL=$(echo "$LABEL" | xargs)  # Trim whitespace
        echo "  Adding: $LABEL"
        if [[ "$DRY_RUN" == true ]]; then
            echo "    [DRY RUN] Would run: gh issue edit $ISSUE --repo $REPO --add-label \"$LABEL\""
        else
            # Create label if it doesn't exist (ignore errors)
            gh label create "$LABEL" --repo "$REPO" 2>/dev/null || true
            gh issue edit "$ISSUE" --repo "$REPO" --add-label "$LABEL"
        fi
    done
fi

echo "✓ Labels updated for issue #$ISSUE"
