#!/usr/bin/env bash
# Create GitHub issues from proposed-issues.json

set -euo pipefail

REPO="${1:-}"
ISSUES_FILE="${2:-proposed-issues.json}"
DRY_RUN="${DRY_RUN:-false}"

if [[ -z "$REPO" ]]; then
  echo "Error: Repository required"
  echo "Usage: $0 <owner/repo> [issues-file]"
  echo ""
  echo "Example: $0 github/copilot-cli proposed-issues.json"
  exit 1
fi

if [[ ! -f "$ISSUES_FILE" ]]; then
  echo "Error: Issues file not found: $ISSUES_FILE"
  exit 1
fi

if ! command -v gh &> /dev/null; then
  echo "Error: gh CLI is required but not installed"
  echo "Install from: https://cli.github.com"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed"
  exit 1
fi

# Verify gh is authenticated
if ! gh auth status &>/dev/null; then
  echo "Error: gh CLI not authenticated"
  echo "Run: gh auth login"
  exit 1
fi

TOTAL=$(jq '.issues | length' "$ISSUES_FILE")

if [[ "$TOTAL" -eq 0 ]]; then
  echo "No issues to create in $ISSUES_FILE"
  exit 0
fi

echo "Creating $TOTAL issue(s) in $REPO..."
echo ""

CREATED_FILE="created-issues.json"
echo '{"created": []}' > "$CREATED_FILE"

for i in $(seq 0 $((TOTAL - 1))); do
  TITLE=$(jq -r ".issues[$i].title" "$ISSUES_FILE")
  BODY=$(jq -r ".issues[$i].body" "$ISSUES_FILE")
  LABELS=$(jq -r ".issues[$i].labels | join(\",\")" "$ISSUES_FILE")
  ASSIGNEE=$(jq -r ".issues[$i].assignee // empty" "$ISSUES_FILE")
  
  echo "[$((i + 1))/$TOTAL] $TITLE"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would create issue with labels: $LABELS"
    continue
  fi
  
  # Build gh issue create command
  CMD=(gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY")
  
  if [[ -n "$LABELS" ]]; then
    CMD+=(--label "$LABELS")
  fi
  
  if [[ -n "$ASSIGNEE" ]]; then
    CMD+=(--assignee "$ASSIGNEE")
  fi
  
  # Create the issue and capture the URL
  if ISSUE_URL=$("${CMD[@]}" 2>&1); then
    ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
    echo "  ✓ Created #$ISSUE_NUMBER: $ISSUE_URL"
    
    # Record in created-issues.json
    jq ".created += [{\"number\": $ISSUE_NUMBER, \"title\": \"$TITLE\", \"url\": \"$ISSUE_URL\"}]" \
      "$CREATED_FILE" > "${CREATED_FILE}.tmp" && mv "${CREATED_FILE}.tmp" "$CREATED_FILE"
  else
    echo "  ✗ Failed to create issue: $ISSUE_URL"
  fi
  
  # Small delay to avoid rate limiting
  sleep 0.5
done

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run complete. No issues were created."
  echo "Remove DRY_RUN=true to create issues."
else
  echo "✓ Done! Created issues saved to $CREATED_FILE"
fi
