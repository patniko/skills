#!/bin/bash
# Apply approved label recommendations
# Usage: ./apply.sh [recommendations.json] [--dry-run]

set -e

INPUT_FILE="${1:-recommendations.json}"
DRY_RUN=false

if [[ "$2" == "--dry-run" ]] || [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  if [[ "$1" == "--dry-run" ]]; then
    INPUT_FILE="recommendations.json"
  fi
fi

DIR="$(dirname "$0")/.."
FULL_PATH="$DIR/$INPUT_FILE"

if [[ ! -f "$FULL_PATH" ]]; then
  echo "Error: $INPUT_FILE not found"
  exit 1
fi

REPO=$(jq -r '.metadata.repository' "$FULL_PATH")
APPROVED=$(jq '[.recommendations[] | select(.approved == true)]' "$FULL_PATH")
COUNT=$(echo "$APPROVED" | jq 'length')

if [[ "$COUNT" -eq 0 ]]; then
  echo "No approved recommendations to apply"
  exit 0
fi

echo "Applying labels to $COUNT issues in $REPO..."
if $DRY_RUN; then
  echo "(DRY RUN - no changes will be made)"
fi
echo ""

echo "$APPROVED" | jq -c '.[]' | while read -r rec; do
  NUMBER=$(echo "$rec" | jq -r '.number')
  TITLE=$(echo "$rec" | jq -r '.title')
  LABELS=$(echo "$rec" | jq -r '.recommended_labels | join(",")')
  
  echo "  #$NUMBER: $TITLE"
  echo "    Labels: $LABELS"
  
  if ! $DRY_RUN; then
    gh issue edit "$NUMBER" --repo "$REPO" --add-label "$LABELS"
    echo "    ✓ Applied"
  else
    echo "    (would apply)"
  fi
  echo ""
done

echo "Done!"
if $DRY_RUN; then
  echo "Run without --dry-run to apply changes"
fi
