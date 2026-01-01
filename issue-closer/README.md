# Issue Closer

Close GitHub issues efficiently with proper context and reasoning. Helps reduce open issue count by closing stale, duplicate, won't-fix, or completed issues.

## Quick Start

```bash
# Close a single issue
gh issue close 123 --repo owner/repo --comment "Closing due to inactivity."

# Close multiple issues with the same reason
./scripts/close-batch.sh owner/repo "Reason for closing" 123 456 789

# Interactive closure based on triage data
./scripts/close-from-triage.sh owner/repo ../issue-triage/triage-data.json
```

## Common Scenarios

- **Stale issues**: Old issues with no activity
- **Duplicates**: Issues already reported elsewhere
- **Won't fix**: Issues outside project scope
- **Already completed**: Issues resolved in a PR or release
- **Insufficient information**: Can't reproduce or act on

## Best Practices

1. Always add a comment explaining why
2. Be respectful and professional
3. Link to related issues or PRs
4. Invite reopening for stale/unclear cases
5. Add labels (e.g., `wontfix`, `duplicate`) before closing

## Integration with Issue Triage

Use triage scores to identify candidates:

```bash
# Find low-priority old issues
jq -r '.issues[] | select(.scores.urgency <= 2 and .age_days > 90) | .number' triage-data.json
```

See [SKILL.md](./SKILL.md) for complete documentation.
