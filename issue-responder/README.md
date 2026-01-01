# Issue Responder

Add strategic comments to GitHub issues to request more information, provide updates, or facilitate resolution. Helps triage issues by engaging with reporters.

## Quick Start

```bash
# Comment on a single issue
gh issue comment 123 --repo owner/repo --body "Thanks! Could you provide more details?"

# Comment on multiple issues with the same message
./scripts/comment-batch.sh owner/repo "Is this still relevant?" 123 456 789

# Request info on unclear issues from triage data
./scripts/request-info.sh owner/repo ../issue-triage/triage-data.json
```

## Common Response Scenarios

- **Request more information**: For unclear issues
- **Cannot reproduce**: Need reproduction steps
- **Check if still relevant**: For older issues
- **Acknowledge and set expectations**: Valid but not immediate
- **Redirect to discussions**: Questions vs. bugs
- **Request testing**: After potential fix
- **Provide workaround**: Temporary solution

## Best Practices

1. Be friendly and professional
2. Be specific in your questions
3. Set expectations and deadlines
4. Provide value (workarounds, context, status)
5. Use markdown for readability
6. Thank contributors

## Comment Templates

Create reusable templates for common scenarios:

```bash
cat > need-info.txt << 'EOF'
Thanks for reporting! To investigate, we need:
1. Steps to reproduce
2. Expected vs actual behavior
3. Environment details
4. Error messages/logs
EOF

gh issue comment 123 --repo owner/repo --body-file need-info.txt
```

See [SKILL.md](./SKILL.md) for complete documentation.
