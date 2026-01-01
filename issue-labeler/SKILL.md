---
name: issue-labeler
description: Apply labels to GitHub issues based on analysis. Works with issue-triage output to categorize issues by type, priority, effort, and AI-delegation potential.
license: MIT
compatibility: Requires gh CLI authenticated with repo write access.
metadata:
  author: patrick
  version: "1.0"
allowed-tools: bash gh jq
---

# Issue Labeler

Apply labels to GitHub issues based on triage analysis and categorization.

## When to Use

- After triaging issues to apply consistent labels
- Categorizing issues by type (bug, feature, docs, etc.)
- Adding priority labels based on triage scores
- Marking issues suitable for AI delegation
- Batch-labeling issues that match certain criteria

## Prerequisites

1. **gh CLI** - Must be installed and authenticated
2. **Write access** - Your token needs `repo` scope for private repos or `public_repo` for public repos

Verify authentication:
```bash
gh auth status
```

## Label Categories

### Priority Labels
Based on the priority score from issue-triage:

| Label | Priority Score | Color |
|-------|---------------|-------|
| `priority: critical` | ≥ 35 | `#b60205` (red) |
| `priority: high` | 30-34 | `#d93f0b` (orange) |
| `priority: medium` | 20-29 | `#fbca04` (yellow) |
| `priority: low` | < 20 | `#0e8a16` (green) |

### Effort Labels
Based on the effort score:

| Label | Effort Score | Color |
|-------|-------------|-------|
| `effort: trivial` | 5 | `#c5def5` (light blue) |
| `effort: small` | 4 | `#bfd4f2` (blue) |
| `effort: medium` | 3 | `#d4c5f9` (purple) |
| `effort: large` | 2 | `#f9d0c4` (peach) |
| `effort: epic` | 1 | `#e99695` (pink) |

### AI Delegation Labels
Based on the delegation score:

| Label | Delegation Score | Color |
|-------|-----------------|-------|
| `good first issue` | 4-5 + clarity ≥ 4 | `#7057ff` (purple) |
| `ai-ready` | 5 | `#0052cc` (blue) |
| `ai-assisted` | 3-4 | `#006b75` (teal) |
| `needs-human` | 1-2 | `#d73a4a` (red) |

### Type Labels
Auto-detected from issue content:

| Label | Detection | Color |
|-------|-----------|-------|
| `bug` | Keywords: error, crash, broken, fail | `#d73a4a` |
| `feature` | Keywords: add, implement, support, new | `#a2eeef` |
| `docs` | Keywords: documentation, readme, typo | `#0075ca` |
| `question` | Keywords: how to, help, question | `#d876e3` |
| `enhancement` | Keywords: improve, better, optimize | `#a2eeef` |

## Scripts

### label-issue.sh

```bash
# Add single label
./scripts/label-issue.sh --repo owner/repo --issue 123 --add "bug"

# Add multiple labels
./scripts/label-issue.sh --repo owner/repo --issue 123 --add "bug,priority: high"

# Remove a label
./scripts/label-issue.sh --repo owner/repo --issue 123 --remove "needs-triage"

# Replace labels (remove old, add new)
./scripts/label-issue.sh --repo owner/repo --issue 123 --add "priority: high" --remove "priority: low"
```

### batch-label.sh

```bash
# Label from triage data with scores
./scripts/batch-label.sh --repo owner/repo --from-triage triage-data.json --apply-scores

# Add label to multiple issues
./scripts/batch-label.sh --repo owner/repo --issues "123,456,789" --add "needs-review"
```

### sync-labels.sh

```bash
# Create all standard labels in the repo
./scripts/sync-labels.sh --repo owner/repo

# Preview what would be created
./scripts/sync-labels.sh --repo owner/repo --dry-run
```

## Workflow

### From Triage Data

1. Run issue-triage to analyze and score issues
2. Run batch-label with --apply-scores to automatically apply:
   - Priority labels based on priority score
   - Effort labels based on effort score
   - AI delegation labels based on delegation + clarity scores
3. Review the applied labels in the GitHub UI

### Labeling Strategy

```
For each scored issue:
  1. Remove any existing priority/effort labels
  2. Add new priority label based on score
  3. Add effort label based on score
  4. If delegation score ≥ 4 AND clarity ≥ 4:
     - Add "good first issue" and/or "ai-ready"
  5. If delegation score ≤ 2:
     - Add "needs-human"
```

## Examples

### Apply Labels from Triage Scores

Given a triage-data.json with scored issues:

```bash
./scripts/batch-label.sh --repo myorg/myrepo --from-triage triage-data.json --apply-scores
```

Output:
```
Processing 42 scored issues...
#123: Added "priority: high", "effort: small", "ai-ready"
#124: Added "priority: medium", "effort: medium"
#125: Added "priority: critical", "effort: trivial", "ai-ready"
...
Done. Labeled 42 issues.
```

### Mark Issues as AI-Ready

```bash
./scripts/batch-label.sh --repo myorg/myrepo --issues "10,15,23" --add "ai-ready"
```

### Create Standard Labels

```bash
./scripts/sync-labels.sh --repo myorg/myrepo
```

Creates all priority, effort, and delegation labels with correct colors.

## LLM Integration

When analyzing issues, output labeling recommendations:

```json
{
  "label_recommendations": [
    {
      "issue": 123,
      "add": ["bug", "priority: high", "effort: small", "ai-ready"],
      "remove": ["needs-triage"],
      "rationale": "Clear bug report with reproduction steps, high priority fix, straightforward fix"
    },
    {
      "issue": 456,
      "add": ["feature", "priority: medium", "effort: large", "needs-human"],
      "remove": ["needs-triage"],
      "rationale": "Feature request requiring design decisions, not suitable for AI"
    }
  ]
}
```

Then execute the recommendations:

```bash
./scripts/label-issue.sh --repo owner/repo --issue 123 \
  --add "bug,priority: high,effort: small,ai-ready" \
  --remove "needs-triage"
```

## Standard Label Definitions

The sync-labels.sh script creates these labels:

```json
{
  "labels": [
    {"name": "priority: critical", "color": "b60205", "description": "Must be addressed immediately"},
    {"name": "priority: high", "color": "d93f0b", "description": "Should be addressed soon"},
    {"name": "priority: medium", "color": "fbca04", "description": "Normal priority"},
    {"name": "priority: low", "color": "0e8a16", "description": "Nice to have"},
    {"name": "effort: trivial", "color": "c5def5", "description": "< 30 minutes"},
    {"name": "effort: small", "color": "bfd4f2", "description": "A few hours"},
    {"name": "effort: medium", "color": "d4c5f9", "description": "A day or two"},
    {"name": "effort: large", "color": "f9d0c4", "description": "A week or more"},
    {"name": "effort: epic", "color": "e99695", "description": "Needs breakdown"},
    {"name": "ai-ready", "color": "0052cc", "description": "Ready for AI coding agent"},
    {"name": "ai-assisted", "color": "006b75", "description": "AI can help but needs human oversight"},
    {"name": "needs-human", "color": "d73a4a", "description": "Requires human judgment/decisions"},
    {"name": "needs-triage", "color": "ededed", "description": "Needs initial triage"},
    {"name": "stale", "color": "ffffff", "description": "No recent activity"},
    {"name": "duplicate", "color": "cfd3d7", "description": "Duplicate of another issue"},
    {"name": "invalid", "color": "e4e669", "description": "Not a valid issue"},
    {"name": "wontfix", "color": "ffffff", "description": "Will not be addressed"}
  ]
}
```

## Notes

- Labels are created automatically if they don't exist
- Running with --dry-run shows what would change without modifying anything
- The --apply-scores flag requires issues to have been scored first
- Labels with special characters need quoting: `"priority: high"`
- Batch operations include rate limiting to avoid API limits
