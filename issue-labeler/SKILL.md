---
name: issue-labeler
description: Add, remove, or update labels on GitHub issues to categorize and organize them. Helps with issue management and filtering.
license: MIT
compatibility: Requires gh CLI (GitHub CLI) to be installed and authenticated.
metadata:
  author: patrick
  version: "1.0"
allowed-tools: gh jq
---

# Issue Labeler

Efficiently categorize and organize GitHub issues using labels.

## When to Use

- After triaging issues and identifying appropriate categories
- To organize issues by type (bug, feature, documentation)
- To mark priority levels (high, medium, low)
- To track status (needs-triage, in-progress, blocked)
- When working with output from the `issue-triage` skill

## Prerequisites

Ensure the GitHub CLI is installed and authenticated:

```bash
gh auth status
# If not authenticated:
gh auth login
```

## Basic Operations

### Add Labels

```bash
gh issue edit <number> --add-label "bug" --repo owner/repo
gh issue edit <number> --add-label "bug,priority-high" --repo owner/repo
```

### Remove Labels

```bash
gh issue edit <number> --remove-label "needs-triage" --repo owner/repo
gh issue edit <number> --remove-label "bug,needs-triage" --repo owner/repo
```

### List Current Labels

```bash
gh issue view <number> --repo owner/repo --json labels --jq '.labels[].name'
```

### List Available Labels in Repo

```bash
gh label list --repo owner/repo
```

## Common Labeling Patterns

### 1. By Issue Type

```bash
# Bug report
gh issue edit <number> --add-label "bug" --repo owner/repo

# Feature request
gh issue edit <number> --add-label "enhancement" --repo owner/repo

# Documentation
gh issue edit <number> --add-label "documentation" --repo owner/repo

# Question (should maybe be a discussion)
gh issue edit <number> --add-label "question" --repo owner/repo
```

### 2. By Priority

```bash
# High priority
gh issue edit <number> --add-label "priority-high" --repo owner/repo

# Medium priority
gh issue edit <number> --add-label "priority-medium" --repo owner/repo

# Low priority
gh issue edit <number> --add-label "priority-low" --repo owner/repo
```

### 3. By Status

```bash
# Needs more information
gh issue edit <number> --add-label "needs-info" --repo owner/repo

# Ready for work
gh issue edit <number> --add-label "ready" --repo owner/repo

# In progress
gh issue edit <number> --add-label "in-progress" --repo owner/repo

# Blocked
gh issue edit <number> --add-label "blocked" --repo owner/repo
```

### 4. By Difficulty/Effort

```bash
# Good first issue
gh issue edit <number> --add-label "good-first-issue" --repo owner/repo

# Help wanted
gh issue edit <number> --add-label "help-wanted" --repo owner/repo

# Large effort
gh issue edit <number> --add-label "epic" --repo owner/repo
```

### 5. Special Categories

```bash
# Won't fix
gh issue edit <number> --add-label "wontfix" --repo owner/repo

# Duplicate
gh issue edit <number> --add-label "duplicate" --repo owner/repo

# Invalid
gh issue edit <number> --add-label "invalid" --repo owner/repo
```

## Batch Labeling

Label multiple issues at once:

```bash
#!/bin/bash
REPO="owner/repo"
ISSUES=(123 456 789)
LABEL="needs-review"

for issue in "${ISSUES[@]}"; do
  gh issue edit "$issue" --add-label "$LABEL" --repo "$REPO"
  echo "Labeled issue #$issue with '$LABEL'"
done
```

## Working with Triage Data

Apply labels based on triage analysis:

```bash
# Example: Label high-importance issues
jq -r '.issues[] | select(.scores.importance != null and .scores.importance >= 4) | .number' triage-data.json | while read issue; do
  gh issue edit "$issue" --add-label "priority-high" --repo owner/repo
  echo "Labeled #$issue as priority-high"
done

# Example: Label AI-ready issues
jq -r '.issues[] | select(.scores.delegation != null and .scores.delegation >= 4) | .number' triage-data.json | while read issue; do
  gh issue edit "$issue" --add-label "good-for-ai" --repo owner/repo
  echo "Labeled #$issue as good-for-ai"
done

# Example: Label quick wins (high effort score = less work)
jq -r '.issues[] | select(.scores.effort != null and .scores.effort >= 4) | .number' triage-data.json | while read issue; do
  gh issue edit "$issue" --add-label "quick-win" --repo owner/repo
  echo "Labeled #$issue as quick-win"
done
```

## Label Management

### Create New Labels

```bash
gh label create "ai-ready" --description "Good candidate for AI coding agent" --color "00ff00" --repo owner/repo
```

### Edit Existing Labels

```bash
gh label edit "bug" --description "Something isn't working" --color "d73a4a" --repo owner/repo
```

### Delete Labels

```bash
gh label delete "old-label" --repo owner/repo
```

### Clone Labels from Another Repo

```bash
# List labels from source repo
gh label list --repo source-owner/source-repo --json name,description,color

# Recreate in target repo (manual for now, or script it)
gh label create "bug" --description "Something isn't working" --color "d73a4a" --repo target-owner/target-repo
```

## Best Practices

1. **Use consistent naming** - Establish label conventions
2. **Don't over-label** - 2-5 labels per issue is usually enough
3. **Clean up as you go** - Remove outdated labels like "needs-triage" after triaging
4. **Use color coding** - Similar label types should have similar colors
5. **Document your labels** - Keep a label guide in your repo docs
6. **Combine with other actions** - Add labels when closing, commenting, etc.
7. **Review label usage** - Periodically audit which labels are actually used

## Label Naming Conventions

Common patterns:

- **Type:** `bug`, `enhancement`, `documentation`, `question`
- **Priority:** `priority-high`, `priority-medium`, `priority-low`
- **Status:** `needs-triage`, `needs-info`, `in-progress`, `blocked`
- **Difficulty:** `good-first-issue`, `help-wanted`, `expert-needed`
- **Area:** `frontend`, `backend`, `api`, `cli`, `docs`
- **Resolution:** `wontfix`, `duplicate`, `invalid`, `works-as-intended`

## Output Format

The `gh` CLI will output confirmation:

```
✓ Edited issue #123 in owner/repo
```

To verify:

```bash
gh issue view <number> --repo owner/repo
```

## Examples

### Example 1: Triage New Bug

```bash
gh issue edit 42 --add-label "bug,needs-triage" --repo myorg/myrepo
```

### Example 2: Mark as Ready After Clarification

```bash
gh issue edit 55 --remove-label "needs-info" --add-label "ready,priority-medium" --repo myorg/myrepo
```

### Example 3: Update Labels as Work Progresses

```bash
# Start work
gh issue edit 88 --remove-label "ready" --add-label "in-progress" --repo myorg/myrepo

# Complete work
gh issue edit 88 --remove-label "in-progress" --repo myorg/myrepo
# (then close the issue)
```

### Example 4: Complex Categorization

```bash
gh issue edit 99 --add-label "enhancement,frontend,good-first-issue" --repo myorg/myrepo
```

### Example 5: Using a Script for Smart Labeling

```bash
#!/bin/bash
# Smart labeling based on issue age and activity

REPO="owner/repo"

gh issue list --repo "$REPO" --json number,createdAt,updatedAt,comments --limit 100 | \
jq -r '.[] | select(
  (now - (.updatedAt | fromdateiso8601)) > 7776000 and # 90 days
  .comments < 2
) | .number' | while read issue; do
  gh issue edit "$issue" --add-label "stale" --repo "$REPO"
  echo "Labeled #$issue as stale"
done
```

## Integration with Issue Triage

Complete workflow:

```bash
# 1. Triage issues
cd issue-triage
./scripts/fetch-issues.sh owner/repo

# 2. Analyze and identify patterns (done by AI/human)

# 3. Apply labels based on analysis
# High priority bugs
jq -r '.issues[] | select(.scores.importance >= 4 and .label_names | contains(["bug"])) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "priority-high" --repo owner/repo

# Quick wins
jq -r '.issues[] | select(.scores.effort >= 4 and .scores.clarity >= 4) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "quick-win" --repo owner/repo

# AI-ready issues
jq -r '.issues[] | select(.scores.delegation >= 4) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "ai-ready" --repo owner/repo
```

## Notes

- Labels are case-sensitive
- Some repos have protected labels or label requirements
- Labels are searchable: `is:issue label:bug label:priority-high`
- GitHub has default labels, but you can customize them
- Label changes trigger notifications to watchers
- Consider using GitHub Projects for more advanced issue tracking
