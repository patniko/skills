#!/bin/bash
# Fetch unlabeled issues from a repository for analysis
# Usage: ./analyze.sh owner/repo [--limit N]

set -e

REPO="${1:?Usage: $0 owner/repo [--limit N]}"
LIMIT="${3:-50}"
OUTPUT_DIR="$(dirname "$0")/.."
OUTPUT_FILE="$OUTPUT_DIR/recommendations.json"

echo "Fetching unlabeled issues from $REPO..."

# Get available labels in the repo
echo "  Fetching repository labels..."
LABELS=$(gh label list --repo "$REPO" --json name,color,description --limit 100)

# Fetch issues with no labels or only 'triage' label
echo "  Fetching issues needing labels..."
ISSUES=$(gh issue list --repo "$REPO" --state open --json number,title,body,labels,createdAt,author,comments --limit "$LIMIT")

# Filter to unlabeled or triage-only issues
UNLABELED=$(echo "$ISSUES" | jq '[.[] | select(.labels | length == 0 or (length == 1 and .[0].name == "triage"))]')

COUNT=$(echo "$UNLABELED" | jq 'length')
echo "  Found $COUNT issues needing labels"

# Build recommendations structure
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --arg repo "$REPO" \
  --arg generated "$NOW" \
  --argjson available_labels "$LABELS" \
  --argjson issues "$UNLABELED" \
  '{
    metadata: {
      repository: $repo,
      generated: $generated,
      total_issues: ($issues | length)
    },
    available_labels: $available_labels,
    recommendations: [
      $issues[] | {
        number: .number,
        title: .title,
        body_preview: (.body | tostring | .[0:500]),
        current_labels: [.labels[].name],
        author: .author.login,
        created_at: .createdAt,
        comment_count: (.comments | length),
        recommended_labels: [],
        confidence: null,
        reasoning: null,
        approved: null
      }
    ]
  }' > "$OUTPUT_FILE"

echo "Saved $COUNT issues to recommendations.json"
echo ""
echo "Next steps:"
echo "  1. Have the LLM analyze recommendations.json and add label suggestions"
echo "  2. Run ./scripts/serve.sh to review recommendations"
echo "  3. Run ./scripts/apply.sh to apply approved labels"
