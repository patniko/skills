---
name: issue-responder
description: Add comments to GitHub issues to request more information, provide updates, or facilitate issue resolution. Helps triage issues by engaging with reporters.
license: MIT
compatibility: Requires gh CLI (GitHub CLI) to be installed and authenticated.
metadata:
  author: patrick
  version: "1.0"
allowed-tools: gh jq
---

# Issue Responder

Add strategic comments to GitHub issues to move them toward resolution.

## When to Use

- After triaging issues and needing to gather more information
- To provide status updates on issues you're investigating
- To ask reporters if issues are still relevant
- To guide issue reporters toward resolution
- When working with output from the `issue-triage` skill

## Prerequisites

Ensure the GitHub CLI is installed and authenticated:

```bash
gh auth status
# If not authenticated:
gh auth login
```

## Common Response Scenarios

### 1. Request More Information

For unclear issues (low clarity score):

```bash
gh issue comment <number> --repo owner/repo --body "Thanks for reporting! To help investigate, could you provide:
- Steps to reproduce
- Expected behavior vs actual behavior
- Environment details (OS, version, etc.)
- Any error messages or logs"
```

### 2. Cannot Reproduce

When you've tried but can't reproduce:

```bash
gh issue comment <number> --repo owner/repo --body "I've tried to reproduce this but haven't been able to. Could you provide more specific steps or a minimal reproduction case? If we can't reproduce it, we may need to close this issue."
```

### 3. Check If Still Relevant

For older issues:

```bash
gh issue comment <number> --repo owner/repo --body "This issue has been open for X months. Is this still relevant with the latest version? If we don't hear back in 14 days, we'll close this as stale."
```

### 4. Acknowledge and Set Expectations

For valid issues you can't address immediately:

```bash
gh issue comment <number> --repo owner/repo --body "Thanks for reporting! This is a valid issue but not something we can prioritize right now. We'll keep this open as a contribution opportunity. PRs welcome!"
```

### 5. Redirect to Discussions

For questions or discussions:

```bash
gh issue comment <number> --repo owner/repo --body "This seems more appropriate for our Discussions section rather than an issue. Could you repost this as a discussion here: [link]? I'll close this issue to keep the issue tracker focused on bugs and features."
```

### 6. Request Testing

When you've made a potential fix:

```bash
gh issue comment <number> --repo owner/repo --body "I believe this may be fixed in the latest version (v2.1.0). Could you test and let us know if you're still seeing this issue?"
```

### 7. Provide Workaround

When there's a temporary solution:

```bash
gh issue comment <number> --repo owner/repo --body "While we work on a proper fix, here's a workaround that should help:
\`\`\`
[code snippet]
\`\`\`
Let us know if this works for you!"
```

## Batch Commenting

Comment on multiple issues with similar context:

```bash
#!/bin/bash
REPO="owner/repo"
ISSUES=(123 456 789)
MESSAGE="Checking in - is this still an issue with the latest version?"

for issue in "${ISSUES[@]}"; do
  gh issue comment "$issue" --repo "$REPO" --body "$MESSAGE"
  echo "Commented on issue #$issue"
done
```

## Working with Triage Data

Target issues based on triage scores:

```bash
# Example: Comment on all unclear issues (low clarity score)
jq -r '.issues[] | select(.scores.clarity != null and .scores.clarity <= 2) | .number' triage-data.json | while read issue; do
  gh issue comment "$issue" --repo owner/repo --body "Could you clarify the requirements for this issue? More details would help us move forward."
done
```

## Using Templates

Create reusable comment templates:

```bash
# Save to a file
cat > need-more-info.txt << 'EOF'
Thanks for the report! To help us investigate, we need:

1. **Steps to reproduce**: Detailed steps to recreate the issue
2. **Expected behavior**: What should happen
3. **Actual behavior**: What actually happens
4. **Environment**: OS, version, configuration
5. **Logs**: Any relevant error messages

If we don't receive this information within 14 days, we'll close the issue.
EOF

# Use the template
gh issue comment 123 --repo owner/repo --body-file need-more-info.txt
```

## Best Practices

1. **Be friendly and professional** - remember there are people behind issues
2. **Be specific** - ask clear questions
3. **Set expectations** - let people know what happens next
4. **Give deadlines** - for responses or actions (e.g., "will close in 14 days")
5. **Provide value** - workarounds, context, or status updates
6. **Link resources** - docs, similar issues, or PRs
7. **Use markdown** - format comments for readability
8. **Thank contributors** - appreciate their time and effort

## Markdown Tips

Format your comments effectively:

```bash
gh issue comment 123 --repo owner/repo --body "## Update

I've investigated this issue. Here's what I found:

- ✅ Confirmed the bug exists in v2.0
- 🔍 Root cause: [explanation]
- 🚧 Working on a fix in PR #456
- 📅 Target release: v2.1

Thanks for your patience!"
```

## Output Format

The `gh` CLI will output confirmation:

```
https://github.com/owner/repo/issues/123#issuecomment-1234567890
```

To verify:

```bash
gh issue view <number> --repo owner/repo --comments
```

## Examples

### Example 1: Request Reproduction Steps

```bash
gh issue comment 42 --repo myorg/myrepo --body "Thanks for reporting! Could you provide step-by-step instructions to reproduce this issue? That will help us investigate."
```

### Example 2: Ask About Current Status

```bash
gh issue comment 55 --repo myorg/myrepo --body "This issue has been open for 6 months. Are you still experiencing this problem with the latest version (v3.2)? If not, we can close this."
```

### Example 3: Multi-line Comment with Code

```bash
gh issue comment 88 --repo myorg/myrepo --body "Here's a workaround until we fix this properly:

\`\`\`javascript
// Add this to your config
config.workaround = true;
\`\`\`

Let me know if this helps!"
```

### Example 4: Using a File

```bash
cat > comment.md << 'EOF'
## Investigation Update

I've looked into this and found:

1. This is a known limitation of the underlying library
2. Fixing it would require a major refactor
3. There's a workaround available (see above comment)

**Decision**: Marking as "wontfix" for now, but we'll revisit in v3.0.

Thanks for understanding!
EOF

gh issue comment 99 --repo myorg/myrepo --body-file comment.md
```

## Notes

- Comments can include @mentions: `@username could you take a look?`
- You can edit comments via the web interface if needed
- Comments trigger notifications to watchers - be mindful of noise
- Use reactions (👍 ❤️ 🎉) for quick acknowledgment without adding comments
- Consider issue templates to prevent unclear issues in the first place
