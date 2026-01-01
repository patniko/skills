#!/usr/bin/env bash
#
# label-batch.sh - Add the same label(s) to multiple issues
#
# Usage:
#   ./label-batch.sh owner/repo "label1,label2" issue1 issue2 issue3 ...
#   echo "123 456 789" | ./label-batch.sh owner/repo "label1,label2"
#

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 owner/repo \"label1,label2\" [issue1 issue2 ...]" >&2
    echo "   Or: echo \"123 456 789\" | $0 owner/repo \"label1,label2\"" >&2
    exit 1
fi

REPO="$1"
LABELS="$2"
shift 2

# Get issues from arguments or stdin
if [[ $# -gt 0 ]]; then
    ISSUES=("$@")
else
    # Read from stdin
    read -r -a ISSUES
fi

if [[ ${#ISSUES[@]} -eq 0 ]]; then
    echo "No issues provided" >&2
    exit 1
fi

echo "Will label ${#ISSUES[@]} issue(s) in $REPO"
echo "Labels: $LABELS"
echo ""

for issue in "${ISSUES[@]}"; do
    echo -n "Labeling issue #$issue... "
    if gh issue edit "$issue" --add-label "$LABELS" --repo "$REPO" 2>/dev/null; then
        echo "✓"
    else
        echo "✗ (failed)"
    fi
done

echo ""
echo "Done!"
