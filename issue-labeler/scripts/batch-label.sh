#!/usr/bin/env bash
#
# batch-label.sh - Apply labels to multiple GitHub issues
#
# Usage:
#   ./batch-label.sh --repo owner/repo --from-triage triage-data.json --apply-scores
#   ./batch-label.sh --repo owner/repo --issues "123,456,789" --add "needs-review"
#

set -euo pipefail

REPO=""
ISSUES=""
TRIAGE_FILE=""
ADD_LABELS=""
REMOVE_LABELS=""
APPLY_SCORES=false
DRY_RUN=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Score to label mappings
get_priority_label() {
    local score=$1
    if [[ $score -ge 35 ]]; then
        echo "priority: critical"
    elif [[ $score -ge 30 ]]; then
        echo "priority: high"
    elif [[ $score -ge 20 ]]; then
        echo "priority: medium"
    else
        echo "priority: low"
    fi
}

get_effort_label() {
    local score=$1
    case $score in
        5) echo "effort: trivial" ;;
        4) echo "effort: small" ;;
        3) echo "effort: medium" ;;
        2) echo "effort: large" ;;
        1) echo "effort: epic" ;;
        *) echo "" ;;
    esac
}

get_delegation_label() {
    local delegation=$1
    local clarity=$2
    
    if [[ $delegation -eq 5 ]]; then
        echo "ai-ready"
    elif [[ $delegation -ge 4 && $clarity -ge 4 ]]; then
        echo "ai-ready"
    elif [[ $delegation -ge 3 ]]; then
        echo "ai-assisted"
    elif [[ $delegation -le 2 ]]; then
        echo "needs-human"
    else
        echo ""
    fi
}

usage() {
    echo "Usage: $0 --repo OWNER/REPO [options]"
    echo ""
    echo "Options:"
    echo "  --repo          Repository in owner/repo format (required)"
    echo "  --issues        Comma-separated list of issue numbers"
    echo "  --from-triage   Path to triage-data.json file"
    echo "  --add           Comma-separated labels to add to all issues"
    echo "  --remove        Comma-separated labels to remove from all issues"
    echo "  --apply-scores  Apply labels based on triage scores"
    echo "  --dry-run       Preview without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 --repo myorg/myrepo --issues '10,15,23' --add 'needs-review'"
    echo "  $0 --repo myorg/myrepo --from-triage triage-data.json --apply-scores"
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
        --add)
            ADD_LABELS="$2"
            shift 2
            ;;
        --remove)
            REMOVE_LABELS="$2"
            shift 2
            ;;
        --apply-scores)
            APPLY_SCORES=true
            shift
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
if [[ -z "$REPO" ]]; then
    echo "Error: --repo is required"
    usage
fi

if [[ -z "$ISSUES" && -z "$TRIAGE_FILE" ]]; then
    echo "Error: Either --issues or --from-triage is required"
    usage
fi

if [[ "$APPLY_SCORES" == true && -z "$TRIAGE_FILE" ]]; then
    echo "Error: --apply-scores requires --from-triage"
    usage
fi

# Build dry-run flag
DRY_RUN_FLAG=""
if [[ "$DRY_RUN" == true ]]; then
    DRY_RUN_FLAG="--dry-run"
fi

SUCCESS=0
FAILED=0

if [[ -n "$ISSUES" ]]; then
    # Simple mode: apply same labels to all issues
    IFS=',' read -ra ISSUE_NUMBERS <<< "$ISSUES"
    
    echo "Labeling ${#ISSUE_NUMBERS[@]} issues..."
    
    for ISSUE in "${ISSUE_NUMBERS[@]}"; do
        OPTS=(--repo "$REPO" --issue "$ISSUE")
        if [[ -n "$ADD_LABELS" ]]; then
            OPTS+=(--add "$ADD_LABELS")
        fi
        if [[ -n "$REMOVE_LABELS" ]]; then
            OPTS+=(--remove "$REMOVE_LABELS")
        fi
        if [[ -n "$DRY_RUN_FLAG" ]]; then
            OPTS+=($DRY_RUN_FLAG)
        fi
        
        if "$SCRIPT_DIR/label-issue.sh" "${OPTS[@]}"; then
            ((SUCCESS++)) || true
        else
            ((FAILED++)) || true
        fi
        
        if [[ "$DRY_RUN" != true ]]; then
            sleep 0.3
        fi
    done
else
    # Triage mode: apply labels based on scores
    if [[ ! -f "$TRIAGE_FILE" ]]; then
        echo "Error: Triage file not found: $TRIAGE_FILE"
        exit 1
    fi
    
    # Get scored issues
    SCORED_ISSUES=$(jq -c '.issues[] | select(.scores.priority != null)' "$TRIAGE_FILE")
    
    if [[ -z "$SCORED_ISSUES" ]]; then
        echo "No scored issues found in $TRIAGE_FILE"
        exit 0
    fi
    
    COUNT=$(echo "$SCORED_ISSUES" | wc -l)
    echo "Processing $COUNT scored issues..."
    echo ""
    
    while IFS= read -r issue_json; do
        ISSUE=$(echo "$issue_json" | jq -r '.number')
        PRIORITY=$(echo "$issue_json" | jq -r '.scores.priority // 0' | cut -d'.' -f1)
        EFFORT=$(echo "$issue_json" | jq -r '.scores.effort // 0')
        DELEGATION=$(echo "$issue_json" | jq -r '.scores.delegation // 0')
        CLARITY=$(echo "$issue_json" | jq -r '.scores.clarity // 0')
        
        # Build label list
        LABELS_TO_ADD=""
        
        if [[ "$APPLY_SCORES" == true ]]; then
            PRIORITY_LABEL=$(get_priority_label "$PRIORITY")
            EFFORT_LABEL=$(get_effort_label "$EFFORT")
            DELEGATION_LABEL=$(get_delegation_label "$DELEGATION" "$CLARITY")
            
            [[ -n "$PRIORITY_LABEL" ]] && LABELS_TO_ADD="$PRIORITY_LABEL"
            [[ -n "$EFFORT_LABEL" ]] && LABELS_TO_ADD="${LABELS_TO_ADD:+$LABELS_TO_ADD,}$EFFORT_LABEL"
            [[ -n "$DELEGATION_LABEL" ]] && LABELS_TO_ADD="${LABELS_TO_ADD:+$LABELS_TO_ADD,}$DELEGATION_LABEL"
        fi
        
        # Add any additional labels
        if [[ -n "$ADD_LABELS" ]]; then
            LABELS_TO_ADD="${LABELS_TO_ADD:+$LABELS_TO_ADD,}$ADD_LABELS"
        fi
        
        if [[ -z "$LABELS_TO_ADD" && -z "$REMOVE_LABELS" ]]; then
            echo "#$ISSUE: No labels to apply"
            continue
        fi
        
        echo "#$ISSUE: Adding [$LABELS_TO_ADD]"
        
        OPTS=(--repo "$REPO" --issue "$ISSUE")
        if [[ -n "$LABELS_TO_ADD" ]]; then
            OPTS+=(--add "$LABELS_TO_ADD")
        fi
        if [[ -n "$REMOVE_LABELS" ]]; then
            OPTS+=(--remove "$REMOVE_LABELS")
        fi
        if [[ -n "$DRY_RUN_FLAG" ]]; then
            OPTS+=($DRY_RUN_FLAG)
        fi
        
        if "$SCRIPT_DIR/label-issue.sh" "${OPTS[@]}"; then
            ((SUCCESS++)) || true
        else
            ((FAILED++)) || true
        fi
        
        if [[ "$DRY_RUN" != true ]]; then
            sleep 0.3
        fi
    done <<< "$SCORED_ISSUES"
fi

echo ""
echo "Done. Labeled: $SUCCESS, Failed: $FAILED"
