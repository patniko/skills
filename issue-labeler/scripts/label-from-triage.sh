#!/usr/bin/env bash
#
# label-from-triage.sh - Apply labels based on triage analysis
#
# Usage:
#   ./label-from-triage.sh owner/repo triage-data.json
#

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 owner/repo triage-data.json" >&2
    exit 1
fi

REPO="$1"
TRIAGE_FILE="$2"

if [[ ! -f "$TRIAGE_FILE" ]]; then
    echo "Error: Triage file not found: $TRIAGE_FILE" >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    exit 1
fi

echo "Smart labeling based on triage scores"
echo "======================================"
echo ""

# High priority issues
echo "Finding high priority issues (importance >= 4)..."
HIGH_PRIORITY=$(jq -r '.issues[] | select(.scores.importance != null and .scores.importance >= 4) | .number' "$TRIAGE_FILE")
if [[ -n "$HIGH_PRIORITY" ]]; then
    COUNT=$(echo "$HIGH_PRIORITY" | wc -l)
    echo "Found $COUNT high priority issue(s)"
    read -p "Add 'priority-high' label to these? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$HIGH_PRIORITY" | while read -r issue; do
            gh issue edit "$issue" --add-label "priority-high" --repo "$REPO" 2>/dev/null && echo "✓ #$issue"
        done
    fi
    echo ""
fi

# AI-ready issues
echo "Finding AI-ready issues (delegation >= 4)..."
AI_READY=$(jq -r '.issues[] | select(.scores.delegation != null and .scores.delegation >= 4) | .number' "$TRIAGE_FILE")
if [[ -n "$AI_READY" ]]; then
    COUNT=$(echo "$AI_READY" | wc -l)
    echo "Found $COUNT AI-ready issue(s)"
    read -p "Add 'good-for-ai' label to these? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to create label if it doesn't exist
        gh label create "good-for-ai" --description "Good candidate for AI coding agent" --color "00ff00" --repo "$REPO" 2>/dev/null || true
        echo "$AI_READY" | while read -r issue; do
            gh issue edit "$issue" --add-label "good-for-ai" --repo "$REPO" 2>/dev/null && echo "✓ #$issue"
        done
    fi
    echo ""
fi

# Quick wins (high effort score = less work)
echo "Finding quick wins (effort >= 4 and clarity >= 4)..."
QUICK_WINS=$(jq -r '.issues[] | select(.scores.effort != null and .scores.effort >= 4 and .scores.clarity != null and .scores.clarity >= 4) | .number' "$TRIAGE_FILE")
if [[ -n "$QUICK_WINS" ]]; then
    COUNT=$(echo "$QUICK_WINS" | wc -l)
    echo "Found $COUNT quick win(s)"
    read -p "Add 'quick-win' label to these? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to create label if it doesn't exist
        gh label create "quick-win" --description "Easy to implement" --color "00ff00" --repo "$REPO" 2>/dev/null || true
        echo "$QUICK_WINS" | while read -r issue; do
            gh issue edit "$issue" --add-label "quick-win" --repo "$REPO" 2>/dev/null && echo "✓ #$issue"
        done
    fi
    echo ""
fi

# Unclear issues needing info
echo "Finding unclear issues (clarity <= 2)..."
UNCLEAR=$(jq -r '.issues[] | select(.scores.clarity != null and .scores.clarity <= 2) | .number' "$TRIAGE_FILE")
if [[ -n "$UNCLEAR" ]]; then
    COUNT=$(echo "$UNCLEAR" | wc -l)
    echo "Found $COUNT unclear issue(s)"
    read -p "Add 'needs-info' label to these? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to create label if it doesn't exist
        gh label create "needs-info" --description "More information needed" --color "d4c5f9" --repo "$REPO" 2>/dev/null || true
        echo "$UNCLEAR" | while read -r issue; do
            gh issue edit "$issue" --add-label "needs-info" --repo "$REPO" 2>/dev/null && echo "✓ #$issue"
        done
    fi
    echo ""
fi

# Low urgency old issues
echo "Finding stale candidates (urgency <= 2, importance <= 2, age > 90 days)..."
STALE=$(jq -r '.issues[] | select(
  .scores.urgency != null and .scores.urgency <= 2 and
  .scores.importance != null and .scores.importance <= 2 and
  .age_days > 90
) | .number' "$TRIAGE_FILE")
if [[ -n "$STALE" ]]; then
    COUNT=$(echo "$STALE" | wc -l)
    echo "Found $COUNT stale candidate(s)"
    read -p "Add 'stale' label to these? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to create label if it doesn't exist
        gh label create "stale" --description "Old issue with low priority" --color "eeeeee" --repo "$REPO" 2>/dev/null || true
        echo "$STALE" | while read -r issue; do
            gh issue edit "$issue" --add-label "stale" --repo "$REPO" 2>/dev/null && echo "✓ #$issue"
        done
    fi
    echo ""
fi

echo "Done!"
