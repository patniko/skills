---
name: issue-labeler
description: Analyze unlabeled GitHub issues and generate label recommendations for review. Supports batch submission after approval.
license: MIT
compatibility: Requires gh CLI authenticated with repo access.
metadata:
  author: patrick
  version: "1.0"
allowed-tools: bash gh jq
---

# Issue Labeler

Generate label recommendations for unlabeled GitHub issues, review them, then submit in batch.

## When to Use

- Repository has many unlabeled or poorly labeled issues
- You want to triage issues without manually reading each one
- Need consistent labeling based on issue content

## Workflow

### Step 1: Generate Recommendations

```bash
# Fetch unlabeled issues and analyze them
./scripts/analyze.sh owner/repo
```

This creates `recommendations.json` with suggested labels for each issue.

### Step 2: Review Recommendations

```bash
# Launch the review UI
./scripts/serve.sh
```

The UI shows:
- Issue title and preview
- Current labels (if any)
- Recommended labels with confidence
- Checkbox to approve/reject each recommendation

### Step 3: Submit Approved Labels

After reviewing in the UI, export approved recommendations and run:

```bash
# Apply approved labels
./scripts/apply.sh recommendations-approved.json
```

Or use the "Submit All" button in the UI to apply via `gh` CLI.

## Label Categories

The analyzer suggests labels from these categories:

| Category | Labels |
|----------|--------|
| Type | `bug`, `enhancement`, `question`, `documentation` |
| Priority | `priority-1`, `priority-2`, `priority-3` |
| Status | `triage`, `needs-info`, `investigating`, `confirmed` |
| Area | (detected from content: `auth`, `cli`, `api`, `ui`, etc.) |

## How Analysis Works

For each unlabeled issue, the LLM analyzes:

1. **Title keywords** - error, feature, how to, crash, etc.
2. **Body content** - stack traces, repro steps, feature requests
3. **Existing patterns** - what labels similar issues have
4. **Repository context** - available labels in the repo

## Files

```
issue-labeler/
├── SKILL.md              # This file
├── review.html           # Review UI for recommendations
├── scripts/
│   ├── analyze.sh        # Fetch and generate recommendations
│   ├── apply.sh          # Apply approved labels
│   └── serve.sh          # Launch review UI
├── recommendations.json  # Generated recommendations (git-ignored)
└── approved.json         # Approved recommendations (git-ignored)
```

## Example Recommendation

```json
{
  "number": 123,
  "title": "App crashes when clicking submit",
  "current_labels": [],
  "recommended_labels": ["bug", "priority-2", "needs-info"],
  "confidence": 0.85,
  "reasoning": "Title indicates crash (bug). No repro steps provided (needs-info). User-facing issue (priority-2).",
  "approved": null
}
```

## Safety

- **No labels applied without explicit approval**
- Review UI shows reasoning for each recommendation
- Dry-run mode available: `./scripts/apply.sh --dry-run`
- All actions logged for audit

## Notes

- Requires `gh` CLI authenticated with write access to issues
- Run `gh auth status` to verify permissions
- For large repos, analyze in batches using `--limit` flag
