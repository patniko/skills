# Meeting to Issues

Convert meeting transcripts into GitHub issues automatically.

## Quick Start

1. **Share transcript**: Provide meeting notes or transcript
2. **Review proposed issues**: Agent extracts and presents action items
3. **Confirm & create**: Approve and create issues in your repo

## Example

```bash
# The agent will guide you through:
# 1. Analyzing your transcript
# 2. Generating proposed issues
# 3. Creating them after your approval

./scripts/preview.sh          # Review proposed issues
./scripts/create-issues.sh owner/repo  # Create in GitHub
```

## Files

- `SKILL.md` - Full documentation
- `scripts/parse.sh` - Parse transcript (template)
- `scripts/preview.sh` - Preview proposed issues
- `scripts/create-issues.sh` - Create issues via gh CLI

## Requirements

- `gh` CLI authenticated
- `jq` for JSON processing

See [SKILL.md](./SKILL.md) for complete documentation.
