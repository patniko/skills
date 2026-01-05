#!/usr/bin/env bash
# Parse meeting transcript and extract action items as JSON

set -euo pipefail

TRANSCRIPT_FILE="${1:-transcript.txt}"
OUTPUT_FILE="${2:-proposed-issues.json}"

if [[ ! -f "$TRANSCRIPT_FILE" ]]; then
  echo "Error: Transcript file not found: $TRANSCRIPT_FILE"
  echo "Usage: $0 <transcript-file> [output-file]"
  exit 1
fi

echo "Parsing transcript: $TRANSCRIPT_FILE"
echo "Output will be saved to: $OUTPUT_FILE"

# Create initial JSON structure
cat > "$OUTPUT_FILE" << 'EOF'
{
  "metadata": {
    "source": "TRANSCRIPT_SOURCE",
    "parsed_at": "TIMESTAMP",
    "total_items": 0
  },
  "issues": []
}
EOF

# Update metadata
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
sed -i.bak "s|TRANSCRIPT_SOURCE|$TRANSCRIPT_FILE|g" "$OUTPUT_FILE"
sed -i.bak "s|TIMESTAMP|$TIMESTAMP|g" "$OUTPUT_FILE"
rm -f "${OUTPUT_FILE}.bak"

echo "✓ Template created: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "1. The AI agent will analyze the transcript and populate proposed-issues.json"
echo "2. Review the proposed issues"
echo "3. Run ./scripts/create-issues.sh <owner/repo> to create them"
