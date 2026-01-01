#!/usr/bin/env bash
#
# close-issue.sh - Close a GitHub issue with a reason and comment
#
# Usage:
#   ./close-issue.sh --repo owner/repo --issue 123 --reason stale
#   ./close-issue.sh --repo owner/repo --issue 456 --reason duplicate --ref 123
#   ./close-issue.sh --repo owner/repo --issue 789 --reason wontfix --comment "Custom comment"
#

set -euo pipefail

REPO=""
ISSUE=""
REASON=""
REF=""
COMMENT=""
DRY_RUN=false

# Default comments for each reason
declare -A DEFAULT_COMMENTS=(
    [stale]="Closing as stale - no activity for an extended period. Please reopen if this is still relevant."
    [duplicate]="Closing as duplicate."
    [invalid]="Closing as this doesn't appear to be a valid issue. If you believe this was closed in error, please provide more details and reopen."
    [wontfix]="Closing as this won't be addressed. This may be working as intended or outside the project scope."
    [completed]="Closing as the work has been completed."
)

# Labels to add for each reason
declare -A REASON_LABELS=(
    [stale]="stale"
    [duplicate]="duplicate"
    [invalid]="invalid"
    [wontfix]="wontfix"
    [completed]=""
)

usage() {
    echo "Usage: $0 --repo OWNER/REPO --issue NUMBER --reason REASON [options]"
    echo ""
    echo "Options:"
    echo "  --repo        Repository in owner/repo format (required)"
    echo "  --issue       Issue number to close (required)"
    echo "  --reason      Close reason: stale, duplicate, invalid, wontfix, completed (required)"
    echo "  --ref         Reference issue number for duplicates (required for duplicate)"
    echo "  --comment     Custom comment (overrides default)"
    echo "  --dry-run     Preview without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 --repo myorg/myrepo --issue 42 --reason stale"
    echo "  $0 --repo myorg/myrepo --issue 42 --reason duplicate --ref 15"
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
        --reason)
            REASON="$2"
            shift 2
            ;;
        --ref)
            REF="$2"
            shift 2
            ;;
        --comment)
            COMMENT="$2"
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
if [[ -z "$REPO" || -z "$ISSUE" || -z "$REASON" ]]; then
    echo "Error: --repo, --issue, and --reason are required"
    usage
fi

# Validate reason
if [[ ! ${DEFAULT_COMMENTS[$REASON]+_} ]]; then
    echo "Error: Invalid reason '$REASON'. Must be one of: stale, duplicate, invalid, wontfix, completed"
    exit 1
fi

# Duplicate requires a reference
if [[ "$REASON" == "duplicate" && -z "$REF" ]]; then
    echo "Error: --ref is required for duplicate reason"
    exit 1
fi

# Build the comment
if [[ -n "$COMMENT" ]]; then
    FINAL_COMMENT="$COMMENT"
elif [[ "$REASON" == "duplicate" ]]; then
    FINAL_COMMENT="Closing as duplicate of #$REF"
else
    FINAL_COMMENT="${DEFAULT_COMMENTS[$REASON]}"
fi

# Get the label to add
LABEL="${REASON_LABELS[$REASON]}"

echo "Closing issue #$ISSUE in $REPO"
echo "  Reason: $REASON"
echo "  Comment: $FINAL_COMMENT"
if [[ -n "$LABEL" ]]; then
    echo "  Label: $LABEL"
fi

if [[ "$DRY_RUN" == true ]]; then
    echo ""
    echo "[DRY RUN] Would execute:"
    if [[ -n "$LABEL" ]]; then
        echo "  gh issue edit $ISSUE --repo $REPO --add-label \"$LABEL\""
    fi
    echo "  gh issue close $ISSUE --repo $REPO --comment \"$FINAL_COMMENT\""
    exit 0
fi

# Add label if specified
if [[ -n "$LABEL" ]]; then
    # Create label if it doesn't exist (ignore errors if it already exists)
    gh label create "$LABEL" --repo "$REPO" 2>/dev/null || true
    gh issue edit "$ISSUE" --repo "$REPO" --add-label "$LABEL"
fi

# Close the issue with comment
gh issue close "$ISSUE" --repo "$REPO" --comment "$FINAL_COMMENT"

echo "✓ Issue #$ISSUE closed successfully"
