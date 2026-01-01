#!/usr/bin/env bash
#
# batch-close.sh - Close multiple GitHub issues at once
#
# Usage:
#   ./batch-close.sh --repo owner/repo --issues "123,456,789" --reason stale
#   ./batch-close.sh --repo owner/repo --from-triage triage-data.json --filter "urgency=1" --reason stale
#

set -euo pipefail

REPO=""
ISSUES=""
TRIAGE_FILE=""
FILTER=""
REASON=""
COMMENT=""
DRY_RUN=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 --repo OWNER/REPO --reason REASON [options]"
    echo ""
    echo "Options:"
    echo "  --repo         Repository in owner/repo format (required)"
    echo "  --issues       Comma-separated list of issue numbers"
    echo "  --from-triage  Path to triage-data.json file"
    echo "  --filter       Filter expression for triage data (e.g., 'urgency=1')"
    echo "  --reason       Close reason: stale, duplicate, invalid, wontfix (required)"
    echo "  --comment      Custom comment for all issues"
    echo "  --dry-run      Preview without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 --repo myorg/myrepo --issues '10,15,23' --reason stale"
    echo "  $0 --repo myorg/myrepo --from-triage triage-data.json --filter 'urgency=1' --reason stale"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO="$2"
            shift 2
            ;;
        --issues)
            ISSUES="$2"
            shift 2
            ;;
        --from-triage)
            TRIAGE_FILE="$2"
            shift 2
            ;;
        --filter)
            FILTER="$2"
            shift 2
            ;;
        --reason)
            REASON="$2"
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
if [[ -z "$REPO" || -z "$REASON" ]]; then
    echo "Error: --repo and --reason are required"
    usage
fi

if [[ -z "$ISSUES" && -z "$TRIAGE_FILE" ]]; then
    echo "Error: Either --issues or --from-triage is required"
    usage
fi

# Build issue list
ISSUE_NUMBERS=()

if [[ -n "$ISSUES" ]]; then
    IFS=',' read -ra ISSUE_NUMBERS <<< "$ISSUES"
elif [[ -n "$TRIAGE_FILE" ]]; then
    if [[ ! -f "$TRIAGE_FILE" ]]; then
        echo "Error: Triage file not found: $TRIAGE_FILE"
        exit 1
    fi
    
    # Parse filter and extract matching issue numbers
    if [[ -n "$FILTER" ]]; then
        # Parse filter like "urgency=1" or "priority<20"
        FIELD=$(echo "$FILTER" | sed -E 's/([a-z_]+).*/\1/')
        OP=$(echo "$FILTER" | sed -E 's/[a-z_]+([=<>]+).*/\1/')
        VALUE=$(echo "$FILTER" | sed -E 's/[a-z_]+[=<>]+//')
        
        # Build jq filter
        case $OP in
            "=")
                JQ_FILTER=".issues[] | select(.scores.$FIELD == $VALUE) | .number"
                ;;
            "<")
                JQ_FILTER=".issues[] | select(.scores.$FIELD != null and .scores.$FIELD < $VALUE) | .number"
                ;;
            ">")
                JQ_FILTER=".issues[] | select(.scores.$FIELD != null and .scores.$FIELD > $VALUE) | .number"
                ;;
            "<=")
                JQ_FILTER=".issues[] | select(.scores.$FIELD != null and .scores.$FIELD <= $VALUE) | .number"
                ;;
            ">=")
                JQ_FILTER=".issues[] | select(.scores.$FIELD != null and .scores.$FIELD >= $VALUE) | .number"
                ;;
            *)
                echo "Error: Unknown operator in filter: $OP"
                exit 1
                ;;
        esac
        
        mapfile -t ISSUE_NUMBERS < <(jq -r "$JQ_FILTER" "$TRIAGE_FILE")
    else
        # No filter - get all issue numbers
        mapfile -t ISSUE_NUMBERS < <(jq -r '.issues[].number' "$TRIAGE_FILE")
    fi
fi

if [[ ${#ISSUE_NUMBERS[@]} -eq 0 ]]; then
    echo "No issues found to close."
    exit 0
fi

echo "Found ${#ISSUE_NUMBERS[@]} issues to close with reason: $REASON"
echo ""

# Build close command options
CLOSE_OPTS=(--repo "$REPO" --reason "$REASON")
if [[ -n "$COMMENT" ]]; then
    CLOSE_OPTS+=(--comment "$COMMENT")
fi
if [[ "$DRY_RUN" == true ]]; then
    CLOSE_OPTS+=(--dry-run)
fi

# Close each issue
SUCCESS=0
FAILED=0

for ISSUE in "${ISSUE_NUMBERS[@]}"; do
    echo "Processing issue #$ISSUE..."
    if "$SCRIPT_DIR/close-issue.sh" --issue "$ISSUE" "${CLOSE_OPTS[@]}"; then
        ((SUCCESS++)) || true
    else
        echo "  Failed to close issue #$ISSUE"
        ((FAILED++)) || true
    fi
    
    # Rate limiting - wait between requests
    if [[ "$DRY_RUN" != true ]]; then
        sleep 0.5
    fi
done

echo ""
echo "Done. Closed: $SUCCESS, Failed: $FAILED"
