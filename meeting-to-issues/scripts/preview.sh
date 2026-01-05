#!/usr/bin/env bash
# Preview proposed issues without creating them

set -euo pipefail

ISSUES_FILE="${1:-proposed-issues.json}"

if [[ ! -f "$ISSUES_FILE" ]]; then
  echo "Error: Issues file not found: $ISSUES_FILE"
  echo "Run parse.sh first to generate proposed issues."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed"
  exit 1
fi

echo "Preview of proposed issues:"
echo "============================"
echo ""

TOTAL=$(jq '.issues | length' "$ISSUES_FILE")

if [[ "$TOTAL" -eq 0 ]]; then
  echo "No issues found in $ISSUES_FILE"
  exit 0
fi

for i in $(seq 0 $((TOTAL - 1))); do
  TITLE=$(jq -r ".issues[$i].title" "$ISSUES_FILE")
  BODY=$(jq -r ".issues[$i].body" "$ISSUES_FILE")
  LABELS=$(jq -r ".issues[$i].labels | join(\", \")" "$ISSUES_FILE")
  ASSIGNEE=$(jq -r ".issues[$i].assignee // \"none\"" "$ISSUES_FILE")
  PRIORITY=$(jq -r ".issues[$i].priority // \"unspecified\"" "$ISSUES_FILE")
  
  echo "Issue $((i + 1)) of $TOTAL"
  echo "─────────────────"
  echo "Title: $TITLE"
  echo "Labels: $LABELS"
  echo "Assignee: $ASSIGNEE"
  echo "Priority: $PRIORITY"
  echo ""
  echo "Description:"
  echo "$BODY"
  echo ""
  echo ""
done

echo "============================"
echo "Total: $TOTAL issue(s)"
echo ""
echo "To create these issues, run:"
echo "  ./scripts/create-issues.sh <owner/repo>"
