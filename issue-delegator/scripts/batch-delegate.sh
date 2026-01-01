#!/usr/bin/env bash
#
# batch-delegate.sh - Delegate multiple GitHub issues at once
#
# Usage:
#   ./batch-delegate.sh --repo owner/repo --from-triage triage-data.json --ai-ready --to copilot
#   ./batch-delegate.sh --repo owner/repo --issues "10,15,23" --to "@alice,@bob"
#

set -euo pipefail

REPO=""
ISSUES=""
TRIAGE_FILE=""
AI_READY=false
NEEDS_HUMAN=false
DELEGATE_TO=""
CONTEXT=""
DRY_RUN=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 --repo OWNER/REPO --to TARGET [options]"
    echo ""
    echo "Options:"
    echo "  --repo          Repository in owner/repo format (required)"
    echo "  --issues        Comma-separated list of issue numbers"
    echo "  --from-triage   Path to triage-data.json file"
    echo "  --ai-ready      Filter to AI-ready issues (delegation >= 4, clarity >= 4)"
    echo "  --needs-human   Filter to issues needing human attention"
    echo "  --to            Delegate target: 'copilot' or '@user1,@user2' (required)"
    echo "  --context       Additional context for all delegations"
    echo "  --dry-run       Preview without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 --repo myorg/myrepo --from-triage triage-data.json --ai-ready --to copilot"
    echo "  $0 --repo myorg/myrepo --issues '10,15,23' --to '@alice,@bob'"
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
        --ai-ready)
            AI_READY=true
            shift
            ;;
        --needs-human)
            NEEDS_HUMAN=true
            shift
            ;;
        --to)
            DELEGATE_TO="$2"
            shift 2
            ;;
        --context)
            CONTEXT="$2"
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
if [[ -z "$REPO" || -z "$DELEGATE_TO" ]]; then
    echo "Error: --repo and --to are required"
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
    
    # Build jq filter based on flags
    if [[ "$AI_READY" == true ]]; then
        JQ_FILTER='.issues[] | select(.scores.delegation != null and .scores.clarity != null and .scores.delegation >= 4 and .scores.clarity >= 4) | .number'
    elif [[ "$NEEDS_HUMAN" == true ]]; then
        JQ_FILTER='.issues[] | select(.scores.delegation != null and .scores.delegation <= 2) | .number'
    else
        # All scored issues
        JQ_FILTER='.issues[] | select(.scores.delegation != null) | .number'
    fi
    
    mapfile -t ISSUE_NUMBERS < <(jq -r "$JQ_FILTER" "$TRIAGE_FILE")
fi

if [[ ${#ISSUE_NUMBERS[@]} -eq 0 ]]; then
    echo "No issues found matching criteria."
    exit 0
fi

echo "Found ${#ISSUE_NUMBERS[@]} issues to delegate to $DELEGATE_TO"
echo ""

# Parse delegate targets for round-robin assignment
IFS=',' read -ra TARGETS <<< "$DELEGATE_TO"
TARGET_COUNT=${#TARGETS[@]}
TARGET_INDEX=0

SUCCESS=0
FAILED=0

# Build common options
COMMON_OPTS=(--repo "$REPO")
if [[ -n "$CONTEXT" ]]; then
    COMMON_OPTS+=(--context "$CONTEXT")
fi
if [[ "$DRY_RUN" == true ]]; then
    COMMON_OPTS+=(--dry-run)
fi

for ISSUE in "${ISSUE_NUMBERS[@]}"; do
    # Get current target (round-robin for multiple targets)
    CURRENT_TARGET="${TARGETS[$TARGET_INDEX]}"
    CURRENT_TARGET=$(echo "$CURRENT_TARGET" | xargs)  # Trim whitespace
    
    echo "Processing issue #$ISSUE -> $CURRENT_TARGET"
    
    if "$SCRIPT_DIR/delegate-issue.sh" --issue "$ISSUE" --to "$CURRENT_TARGET" "${COMMON_OPTS[@]}"; then
        ((SUCCESS++)) || true
    else
        echo "  Failed to delegate issue #$ISSUE"
        ((FAILED++)) || true
    fi
    
    # Move to next target (round-robin)
    TARGET_INDEX=$(( (TARGET_INDEX + 1) % TARGET_COUNT ))
    
    # Rate limiting
    if [[ "$DRY_RUN" != true ]]; then
        sleep 0.5
    fi
done

echo ""
echo "Done. Delegated: $SUCCESS, Failed: $FAILED"
