# Complete Issue Management Workflow

This guide demonstrates how to use the issue management skills together to reduce open and untriaged issues.

## Overview

The skills work together in this workflow:

1. **issue-triage** - Analyze and prioritize issues
2. **issue-labeler** - Organize issues with labels  
3. **issue-responder** - Engage with issue reporters
4. **issue-closer** - Close issues that won't be addressed

## Complete Workflow Example

### Step 1: Fetch and Triage Issues

```bash
cd issue-triage
./scripts/fetch-issues.sh owner/repo

# Analyze the issues (AI/human review of triage-data.json)
# Add scores and priority analysis to the JSON
```

### Step 2: Apply Smart Labels

```bash
cd ../issue-labeler
./scripts/label-from-triage.sh owner/repo ../issue-triage/triage-data.json
```

This interactive script will:
- Label high-priority issues (importance >= 4) with `priority-high`
- Label AI-ready issues (delegation >= 4) with `good-for-ai`
- Label quick wins (effort >= 4, clarity >= 4) with `quick-win`
- Label unclear issues (clarity <= 2) with `needs-info`
- Label stale candidates with `stale`

### Step 3: Request Information

For unclear issues that need more details:

```bash
cd ../issue-responder
./scripts/request-info.sh owner/repo ../issue-triage/triage-data.json
```

This adds a standard comment requesting:
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Logs/screenshots

### Step 4: Close Appropriate Issues

For issues that should be closed:

```bash
cd ../issue-closer
./scripts/close-from-triage.sh owner/repo ../issue-triage/triage-data.json
```

This interactive script helps you review and close:
- Low-priority stale issues
- Issues with insufficient information
- Duplicates and won't-fix items

## Example: Focused Cleanup Session

Here's a 30-minute cleanup session workflow:

```bash
# 1. Fetch current state
cd issue-triage
./scripts/fetch-issues.sh myorg/myrepo
cd ..

# 2. Quick triage analysis (you do this part)
# Review top issues, add scores to triage-data.json

# 3. Label the most important issues
cd issue-labeler
jq -r '.issues[] | select(.scores.importance >= 4) | .number' \
  ../issue-triage/triage-data.json | \
  ./scripts/label-batch.sh myorg/myrepo "priority-high"

# 4. Request info on unclear issues
cd ../issue-responder
jq -r '.issues[] | select(.scores.clarity <= 2) | .number' \
  ../issue-triage/triage-data.json | head -5 | \
  ./scripts/comment-batch.sh myorg/myrepo "Thanks for reporting! Could you provide more details? [specific questions based on the issue]"

# 5. Close stale low-priority issues
cd ../issue-closer
jq -r '.issues[] | select(.scores.urgency <= 1 and .age_days > 180) | .number' \
  ../issue-triage/triage-data.json | \
  ./scripts/close-batch.sh myorg/myrepo "Closing due to 6+ months of inactivity. Please reopen if still relevant."
```

## Common Patterns

### Pattern 1: Clear the Backlog

Focus on old, low-priority issues:

```bash
# Find candidates
jq -r '.issues[] | select(
  .scores.importance <= 2 and 
  .scores.urgency <= 2 and 
  .age_days > 90
) | "\(.number) - \(.title)"' triage-data.json

# Close them
jq -r '.issues[] | select(
  .scores.importance <= 2 and 
  .scores.urgency <= 2 and 
  .age_days > 90
) | .number' triage-data.json | \
  xargs -I {} gh issue close {} --repo owner/repo \
    --comment "Closing as low priority with no recent activity. Please reopen if this becomes relevant."
```

### Pattern 2: Prepare Issues for AI Agents

Identify and label AI-ready work:

```bash
# Label AI-ready issues
jq -r '.issues[] | select(.scores.delegation >= 4) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "good-for-ai" --repo owner/repo

# Also add good-first-issue for easy ones
jq -r '.issues[] | select(.scores.delegation >= 4 and .scores.effort >= 4) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "good-first-issue" --repo owner/repo
```

### Pattern 3: Engage with Unclear Issues

Get the information needed to proceed:

```bash
# Find unclear issues
jq -r '.issues[] | select(.scores.clarity <= 2) | .number' triage-data.json

# Comment requesting details
cat > request-details.txt << 'EOF'
Thanks for reporting! To help us investigate, could you provide:

1. **Steps to reproduce**: Detailed steps to recreate the issue
2. **Expected behavior**: What should happen
3. **Actual behavior**: What actually happens
4. **Environment**: OS, version, configuration
5. **Logs**: Any error messages or screenshots

We'll follow up once we have these details. Thanks!
EOF

jq -r '.issues[] | select(.scores.clarity <= 2) | .number' triage-data.json | \
  xargs -I {} gh issue comment {} --repo owner/repo --body-file request-details.txt

# Add needs-info label
jq -r '.issues[] | select(.scores.clarity <= 2) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "needs-info" --repo owner/repo
```

### Pattern 4: Priority Triage

Mark urgent issues for immediate attention:

```bash
# High priority: urgent AND important
jq -r '.issues[] | select(.scores.urgency >= 4 and .scores.importance >= 4) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "priority-high,urgent" --repo owner/repo

# Medium priority: important but not urgent
jq -r '.issues[] | select(.scores.importance >= 3 and .scores.urgency <= 3) | .number' triage-data.json | \
  xargs -I {} gh issue edit {} --add-label "priority-medium" --repo owner/repo
```

## Metrics and Tracking

Monitor your progress:

```bash
# Count open issues before
BEFORE=$(gh issue list --repo owner/repo --state open --json number | jq length)

# Do your cleanup work...

# Count open issues after
AFTER=$(gh issue list --repo owner/repo --state open --json number | jq length)

echo "Reduced open issues from $BEFORE to $AFTER ($(($BEFORE - $AFTER)) closed)"
```

## Tips

1. **Start small** - Don't try to triage everything at once
2. **Be consistent** - Use the same labels and patterns
3. **Communicate** - Always explain why you're closing or requesting info
4. **Batch similar work** - Group similar issues for efficiency
5. **Use filters** - GitHub search syntax helps find specific issues
6. **Save queries** - Create saved searches for common filters
7. **Schedule regular sessions** - Weekly triage keeps things manageable

## Advanced: Full Automation

Create a script that does a full triage cycle:

```bash
#!/bin/bash
REPO="owner/repo"

echo "=== Fetch Issues ==="
cd issue-triage && ./scripts/fetch-issues.sh "$REPO"

echo -e "\n=== Label Issues ==="
cd ../issue-labeler && ./scripts/label-from-triage.sh "$REPO" ../issue-triage/triage-data.json

echo -e "\n=== Request Info ==="
cd ../issue-responder && ./scripts/request-info.sh "$REPO" ../issue-triage/triage-data.json

echo -e "\n=== Close Stale Issues ==="
cd ../issue-closer && ./scripts/close-from-triage.sh "$REPO" ../issue-triage/triage-data.json

echo -e "\n=== Done! ==="
```

Save this as `full-triage.sh` and run it periodically.

## Resources

- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GitHub Issues Documentation](https://docs.github.com/en/issues)
- [Issue Triage Best Practices](https://opensource.guide/best-practices/)
- [Agent Skills Specification](https://agentskills.io)
