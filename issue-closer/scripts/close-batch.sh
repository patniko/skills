#!/usr/bin/env bash
#
# close-batch.sh - Close multiple issues with the same reason
#
# Usage:
#   ./close-batch.sh owner/repo "reason" issue1 issue2 issue3 ...
#   echo "123 456 789" | ./close-batch.sh owner/repo "reason"
#

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 owner/repo \"reason\" [issue1 issue2 ...]" >&2
    echo "   Or: echo \"123 456 789\" | $0 owner/repo \"reason\"" >&2
    exit 1
fi

REPO="$1"
REASON="$2"
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

echo "Will close ${#ISSUES[@]} issue(s) in $REPO"
echo "Reason: $REASON"
echo ""

for issue in "${ISSUES[@]}"; do
    echo -n "Closing issue #$issue... "
    if gh issue close "$issue" --repo "$REPO" --comment "$REASON" 2>/dev/null; then
        echo "✓"
    else
        echo "✗ (failed)"
    fi
done

echo ""
echo "Done!"
