---
name: issue-closer
description: Close GitHub issues with appropriate reasons and comments. Works with issue-triage output to batch-close stale, duplicate, invalid, or wontfix issues.
license: MIT
compatibility: Requires gh CLI authenticated with repo write access.
metadata:
  author: patrick
  version: "1.0"
allowed-tools: bash gh jq
---

# Issue Closer

Close GitHub issues with appropriate reasons, comments, and labels.

## When to Use

- After triaging issues and identifying ones to close
- Cleaning up stale issues that haven't been updated in months
- Closing duplicates with references to the original
- Rejecting invalid issues or feature requests that won't be implemented
- Batch-closing issues that match certain criteria

## Prerequisites

1. **gh CLI** - Must be installed and authenticated
2. **Write access** - Your token needs `repo` scope for private repos or `public_repo` for public repos

Verify authentication:
```bash
gh auth status
```

## Close Reasons

| Reason | Label Added | When to Use |
|--------|-------------|-------------|
| `stale` | `stale` | No activity for 90+ days, no longer relevant |
| `duplicate` | `duplicate` | Already reported in another issue |
| `invalid` | `invalid` | Not a real bug, user error, or can't reproduce |
| `wontfix` | `wontfix` | Working as intended or won't be addressed |
| `completed` | (none) | Work done but issue wasn't closed properly |

## Scripts

### close-issue.sh

```bash
./scripts/close-issue.sh --repo owner/repo --issue 123 --reason stale
./scripts/close-issue.sh --repo owner/repo --issue 456 --reason duplicate --ref 123
./scripts/close-issue.sh --repo owner/repo --issue 789 --reason wontfix --comment "This is by design"
```

### batch-close.sh

```bash
# Close multiple issues at once
./scripts/batch-close.sh --repo owner/repo --issues "123,456,789" --reason stale

# Close from triage data (issues with urgency score of 1)
./scripts/batch-close.sh --repo owner/repo --from-triage triage-data.json --filter "urgency=1" --reason stale
```

## Workflow

### From Triage Data

1. Run issue-triage to analyze issues
2. Identify issues to close based on scores:
   - Urgency = 1 (someday/maybe) + Age > 180 days → **stale**
   - Clarity = 1 (confused/no actionable request) → **invalid**
   - Importance = 1 (trivial/questionable value) → consider **wontfix**
3. Use this skill to close them with appropriate reasons

### Manual Workflow

1. Review the issue to confirm it should be closed
2. Determine the appropriate reason
3. Run the close command with an optional comment
4. Verify the issue was closed correctly

## Examples

### Close a Stale Issue

```bash
./scripts/close-issue.sh --repo myorg/myrepo --issue 42 --reason stale
```

This will:
- Add label: `stale`
- Add comment: "Closing as stale - no activity for an extended period. Please reopen if this is still relevant."
- Close the issue

### Close a Duplicate

```bash
./scripts/close-issue.sh --repo myorg/myrepo --issue 42 --reason duplicate --ref 15
```

This will:
- Add label: `duplicate`
- Add comment: "Closing as duplicate of #15"
- Close the issue

### Close with Custom Comment

```bash
./scripts/close-issue.sh --repo myorg/myrepo --issue 42 --reason wontfix --comment "This behavior is intentional. See docs at https://..."
```

### Batch Close from Analysis

After analyzing triage-data.json and identifying issues 10, 15, and 23 as stale:

```bash
./scripts/batch-close.sh --repo myorg/myrepo --issues "10,15,23" --reason stale
```

## LLM Integration

When analyzing issues from triage data, output recommendations in this format:

```json
{
  "close_recommendations": [
    {
      "issue": 123,
      "reason": "stale",
      "confidence": "high",
      "rationale": "No activity for 8 months, original reporter hasn't responded to questions"
    },
    {
      "issue": 456,
      "reason": "duplicate",
      "ref": 100,
      "confidence": "high",
      "rationale": "Exact same bug report as #100"
    },
    {
      "issue": 789,
      "reason": "invalid",
      "confidence": "medium",
      "rationale": "Appears to be user configuration error, not a bug"
    }
  ]
}
```

Then execute:
```bash
./scripts/close-issue.sh --repo owner/repo --issue 123 --reason stale
./scripts/close-issue.sh --repo owner/repo --issue 456 --reason duplicate --ref 100
./scripts/close-issue.sh --repo owner/repo --issue 789 --reason invalid
```

## Default Comments by Reason

| Reason | Default Comment |
|--------|-----------------|
| stale | "Closing as stale - no activity for an extended period. Please reopen if this is still relevant." |
| duplicate | "Closing as duplicate of #REF" (requires --ref) |
| invalid | "Closing as this doesn't appear to be a valid issue. If you believe this was closed in error, please provide more details and reopen." |
| wontfix | "Closing as this won't be addressed. This may be working as intended or outside the project scope." |
| completed | "Closing as the work has been completed." |

## Notes

- Always review issues before closing - automation should assist, not replace judgment
- For duplicates, always reference the original issue with --ref
- Consider adding a comment explaining the closure for non-obvious cases
- The batch script has a --dry-run option to preview without making changes
- Labels are created automatically if they don't exist
