# Issue Labeler

Add, remove, or update labels on GitHub issues to categorize and organize them. Helps with issue management and filtering.

## Quick Start

```bash
# Add a label
gh issue edit 123 --add-label "bug" --repo owner/repo

# Add multiple labels
gh issue edit 123 --add-label "bug,priority-high" --repo owner/repo

# Remove a label
gh issue edit 123 --remove-label "needs-triage" --repo owner/repo

# Batch label issues
./scripts/label-batch.sh owner/repo "priority-high" 123 456 789

# Smart labeling from triage data
./scripts/label-from-triage.sh owner/repo ../issue-triage/triage-data.json
```

## Common Label Categories

- **Type**: `bug`, `enhancement`, `documentation`, `question`
- **Priority**: `priority-high`, `priority-medium`, `priority-low`
- **Status**: `needs-triage`, `needs-info`, `in-progress`, `blocked`
- **Difficulty**: `good-first-issue`, `help-wanted`, `expert-needed`
- **Resolution**: `wontfix`, `duplicate`, `invalid`

## Integration with Issue Triage

Apply labels based on triage scores:

```bash
# High priority issues
jq -r '.issues[] | select(.scores.importance >= 4) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "priority-high" --repo owner/repo

# AI-ready issues  
jq -r '.issues[] | select(.scores.delegation >= 4) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "good-for-ai" --repo owner/repo

# Quick wins
jq -r '.issues[] | select(.scores.effort >= 4 and .scores.clarity >= 4) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "quick-win" --repo owner/repo
```

## Best Practices

1. Use consistent naming conventions
2. Don't over-label (2-5 per issue)
3. Clean up as you go
4. Use color coding
5. Document your label system
6. Combine with other actions

See [SKILL.md](./SKILL.md) for complete documentation.
