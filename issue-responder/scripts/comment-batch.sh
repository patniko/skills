#!/usr/bin/env bash
#
# comment-batch.sh - Add the same comment to multiple issues
#
# Usage:
#   ./comment-batch.sh owner/repo "comment text" issue1 issue2 issue3 ...
#   echo "123 456 789" | ./comment-batch.sh owner/repo "comment text"
#

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 owner/repo \"comment text\" [issue1 issue2 ...]" >&2
    echo "   Or: echo \"123 456 789\" | $0 owner/repo \"comment text\"" >&2
    exit 1
fi

REPO="$1"
COMMENT="$2"
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

echo "Will comment on ${#ISSUES[@]} issue(s) in $REPO"
echo "Comment: $COMMENT"
echo ""

for issue in "${ISSUES[@]}"; do
    echo -n "Commenting on issue #$issue... "
    if gh issue comment "$issue" --repo "$REPO" --body "$COMMENT" 2>/dev/null; then
        echo "✓"
    else
        echo "✗ (failed)"
    fi
done

echo ""
echo "Done!"
