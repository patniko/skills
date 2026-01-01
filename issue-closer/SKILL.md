---
name: issue-closer
description: Close GitHub issues with appropriate reasoning and comments. Helps reduce open issue count by closing stale, duplicate, won't-fix, or completed issues.
license: MIT
compatibility: Requires gh CLI (GitHub CLI) to be installed and authenticated.
metadata:
  author: patrick
  version: "1.0"
allowed-tools: gh jq
---

# Issue Closer

Close GitHub issues efficiently with proper context and reasoning.

## When to Use

- After triaging issues and identifying ones that should be closed
- When issues are stale, duplicates, won't-fix, or already completed
- To reduce open issue count and clean up the backlog
- When working with output from the `issue-triage` skill

## Prerequisites

Ensure the GitHub CLI is installed and authenticated:

```bash
gh auth status
# If not authenticated:
gh auth login
```

## Common Closing Scenarios

### 1. Stale Issues

Issues that are old with no recent activity:

```bash
gh issue close <number> --repo owner/repo --comment "Closing due to inactivity. This issue has been open for X days without updates. Please reopen if this is still relevant."
```

### 2. Duplicate Issues

Issues that duplicate existing ones:

```bash
gh issue close <number> --repo owner/repo --comment "Closing as duplicate of #<other-number>."
```

### 3. Won't Fix / Out of Scope

Issues that won't be addressed:

```bash
gh issue close <number> --repo owner/repo --comment "Closing as this is outside the scope of this project. [Explanation of why]"
```

### 4. Already Completed

Issues that have been resolved:

```bash
gh issue close <number> --repo owner/repo --comment "Closing as completed. This was resolved in [PR/commit/release]."
```

### 5. Cannot Reproduce / Insufficient Information

Issues lacking enough detail to act on:

```bash
gh issue close <number> --repo owner/repo --comment "Closing due to insufficient information to reproduce or act on. Please reopen with more details if this is still an issue."
```

## Batch Closing

Close multiple issues at once using a script:

```bash
#!/bin/bash
REPO="owner/repo"
ISSUES=(123 456 789)
REASON="Closing due to inactivity."

for issue in "${ISSUES[@]}"; do
  gh issue close "$issue" --repo "$REPO" --comment "$REASON"
  echo "Closed issue #$issue"
done
```

## Working with Triage Data

If you have output from `issue-triage`, you can filter and close issues:

```bash
# Example: Close all issues with delegation score = 1 and urgency score = 1
jq -r '.issues[] | select(.scores.delegation == 1 and .scores.urgency == 1) | .number' triage-data.json | while read issue; do
  gh issue close "$issue" --repo owner/repo --comment "Closing as low priority and not suitable for current work."
done
```

## Best Practices

1. **Always add a comment** explaining why the issue is being closed
2. **Be respectful** - remember there are people behind these issues
3. **Give context** - help others understand the decision
4. **Link to related issues/PRs** when closing as duplicate or completed
5. **Invite reopening** for stale/insufficient info cases if the issue is still relevant
6. **Review before closing** - double-check you're closing the right issues
7. **Add labels** before closing (e.g., `wontfix`, `duplicate`) for better tracking:
   ```bash
   gh issue edit <number> --add-label "wontfix" --repo owner/repo
   gh issue close <number> --repo owner/repo --comment "Reason..."
   ```

## Output Format

The `gh` CLI will output confirmation:

```
✓ Closed issue #123 in owner/repo
```

To verify:

```bash
gh issue view <number> --repo owner/repo
```

## Examples

### Example 1: Close Stale Issue

```bash
gh issue close 42 --repo myorg/myrepo --comment "Closing due to 90+ days of inactivity. Please reopen if this is still relevant."
```

### Example 2: Close Duplicate with Label

```bash
gh issue edit 55 --add-label "duplicate" --repo myorg/myrepo
gh issue close 55 --repo myorg/myrepo --comment "Duplicate of #50. Closing in favor of that issue."
```

### Example 3: Close Completed Issue

```bash
gh issue close 88 --repo myorg/myrepo --comment "Fixed in PR #90 and released in v2.1.0. Thanks for reporting!"
```

### Example 4: Interactive Closure

For careful review, list issues first:

```bash
gh issue list --repo owner/repo --label "needs-triage" --limit 10
# Review each one
gh issue view 123 --repo owner/repo
# Close if appropriate
gh issue close 123 --repo owner/repo --comment "Your reasoning here"
```

## Notes

- Closed issues can always be reopened if needed: `gh issue reopen <number>`
- Consider adding "reason" labels (`wontfix`, `duplicate`, `invalid`) before closing
- You can also close via the web interface if you prefer
- Bulk operations should be done carefully - verify your filters first
- Some repos use issue templates or require specific closing procedures
