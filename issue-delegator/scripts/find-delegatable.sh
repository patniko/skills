#!/usr/bin/env bash
#
# find-delegatable.sh - Find issues suitable for delegation from triage data
#
# Usage:
#   ./find-delegatable.sh --from-triage triage-data.json --ai-ready
#   ./find-delegatable.sh --from-triage triage-data.json --needs-human
#

set -euo pipefail

TRIAGE_FILE=""
AI_READY=false
NEEDS_HUMAN=false
OUTPUT_FORMAT="json"

usage() {
    echo "Usage: $0 --from-triage FILE [options]"
    echo ""
    echo "Options:"
    echo "  --from-triage   Path to triage-data.json file (required)"
    echo "  --ai-ready      Find issues ready for AI delegation"
    echo "  --needs-human   Find issues needing human attention"
    echo "  --format        Output format: json (default) or table"
    echo ""
    echo "Examples:"
    echo "  $0 --from-triage triage-data.json --ai-ready"
    echo "  $0 --from-triage triage-data.json --needs-human --format table"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
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
        --format)
            OUTPUT_FORMAT="$2"
            shift 2
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

if [[ -z "$TRIAGE_FILE" ]]; then
    echo "Error: --from-triage is required"
    usage
fi

if [[ ! -f "$TRIAGE_FILE" ]]; then
    echo "Error: Triage file not found: $TRIAGE_FILE"
    exit 1
fi

# Determine which issues to find
if [[ "$AI_READY" == true ]]; then
    CATEGORY="ai_ready"
    JQ_FILTER='
        .issues 
        | map(select(.scores.delegation != null and .scores.clarity != null and .scores.delegation >= 4 and .scores.clarity >= 4))
        | map({
            issue: .number,
            title: .title,
            delegation_score: .scores.delegation,
            clarity_score: .scores.clarity,
            effort_score: .scores.effort,
            priority_score: .scores.priority,
            recommendation: (
                if .scores.delegation == 5 and .scores.clarity == 5 and .scores.effort >= 4 then
                    "Perfect for AI - trivial, crystal clear"
                elif .scores.delegation == 5 and .scores.clarity >= 4 then
                    "Excellent for AI - clear scope, well-defined"
                elif .scores.delegation >= 4 and .scores.clarity >= 4 then
                    "Good for AI - may need minor clarification"
                else
                    "Suitable for AI with some oversight"
                end
            ),
            url: .url
        })
        | sort_by(-.delegation_score, -.clarity_score)
    '
elif [[ "$NEEDS_HUMAN" == true ]]; then
    CATEGORY="needs_human"
    JQ_FILTER='
        .issues 
        | map(select(.scores.delegation != null and .scores.delegation <= 2))
        | map({
            issue: .number,
            title: .title,
            delegation_score: .scores.delegation,
            clarity_score: .scores.clarity,
            effort_score: .scores.effort,
            priority_score: .scores.priority,
            recommendation: (
                if .scores.delegation == 1 then
                    "Human only - requires context, stakeholder input, or creative direction"
                else
                    "Difficult for AI - ambiguous requirements, needs design decisions"
                end
            ),
            url: .url
        })
        | sort_by(-.priority_score)
    '
else
    # Show both categories
    CATEGORY="all"
    JQ_FILTER='
        {
            ai_ready: [
                .issues[] 
                | select(.scores.delegation != null and .scores.clarity != null and .scores.delegation >= 4 and .scores.clarity >= 4)
                | {issue: .number, title: .title, delegation: .scores.delegation, clarity: .scores.clarity}
            ],
            needs_human: [
                .issues[] 
                | select(.scores.delegation != null and .scores.delegation <= 2)
                | {issue: .number, title: .title, delegation: .scores.delegation, priority: .scores.priority}
            ],
            summary: {
                total_scored: ([.issues[] | select(.scores.delegation != null)] | length),
                ai_ready_count: ([.issues[] | select(.scores.delegation != null and .scores.clarity != null and .scores.delegation >= 4 and .scores.clarity >= 4)] | length),
                needs_human_count: ([.issues[] | select(.scores.delegation != null and .scores.delegation <= 2)] | length)
            }
        }
    '
fi

# Run the query
RESULT=$(jq "$JQ_FILTER" "$TRIAGE_FILE")

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    if [[ "$CATEGORY" == "all" ]]; then
        echo "$RESULT"
    else
        jq -n --argjson items "$RESULT" --arg category "$CATEGORY" '{
            ($category): $items,
            total: ($items | length)
        }'
    fi
elif [[ "$OUTPUT_FORMAT" == "table" ]]; then
    if [[ "$CATEGORY" == "all" ]]; then
        echo "=== AI Ready Issues ==="
        echo "$RESULT" | jq -r '.ai_ready[] | "#\(.issue)\t\(.delegation)/\(.clarity)\t\(.title)"'
        echo ""
        echo "=== Needs Human Issues ==="
        echo "$RESULT" | jq -r '.needs_human[] | "#\(.issue)\t\(.delegation)\t\(.title)"'
        echo ""
        echo "=== Summary ==="
        echo "$RESULT" | jq -r '"Total scored: \(.summary.total_scored), AI ready: \(.summary.ai_ready_count), Needs human: \(.summary.needs_human_count)"'
    else
        echo "Issue	Del	Clarity	Effort	Title"
        echo "-----	---	-------	------	-----"
        echo "$RESULT" | jq -r '.[] | "#\(.issue)\t\(.delegation_score)\t\(.clarity_score)\t\(.effort_score // "-")\t\(.title)"'
        echo ""
        echo "Total: $(echo "$RESULT" | jq 'length') issues"
    fi
fi
