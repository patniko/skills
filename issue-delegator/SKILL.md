---
name: issue-delegator
description: Delegate GitHub issues to AI coding agents or human contributors. Works with issue-triage output to identify and assign AI-ready issues.
license: MIT
compatibility: Requires gh CLI authenticated with repo write access.
metadata:
  author: patrick
  version: "1.0"
allowed-tools: bash gh jq
---

# Issue Delegator

Delegate GitHub issues to AI coding agents or human contributors based on triage analysis.

## When to Use

- After triaging issues to identify AI-ready work
- Assigning issues to Copilot Coding Agent or similar AI tools
- Distributing work to human contributors
- Creating a queue of issues for automated processing
- Reducing untriaged issue count by assigning owners

## Prerequisites

1. **gh CLI** - Must be installed and authenticated
2. **Write access** - Your token needs `repo` scope for private repos or `public_repo` for public repos
3. **Copilot Coding Agent** - For AI delegation (if using GitHub Copilot)

Verify authentication:
```bash
gh auth status
```

## Delegation Types

### AI Delegation
Issues suitable for AI coding agents:
- **Delegation score**: 4-5
- **Clarity score**: 4-5
- **Has clear acceptance criteria**
- **Isolated, well-scoped changes**

### Human Delegation
Issues requiring human judgment:
- **Delegation score**: 1-3
- **Needs design decisions**
- **Requires stakeholder input**
- **Complex architectural changes**

## Scripts

### delegate-issue.sh

```bash
# Delegate to Copilot Coding Agent (creates a task)
./scripts/delegate-issue.sh --repo owner/repo --issue 123 --to copilot

# Assign to a human contributor
./scripts/delegate-issue.sh --repo owner/repo --issue 123 --to @username

# Delegate with additional context
./scripts/delegate-issue.sh --repo owner/repo --issue 123 --to copilot \
  --context "Focus on the API endpoint, don't modify the UI"
```

### batch-delegate.sh

```bash
# Delegate AI-ready issues from triage data
./scripts/batch-delegate.sh --repo owner/repo --from-triage triage-data.json --ai-ready --to copilot

# Assign issues to team members round-robin
./scripts/batch-delegate.sh --repo owner/repo --issues "10,15,23" --to "@alice,@bob,@charlie"
```

### find-delegatable.sh

```bash
# Find issues ready for AI delegation
./scripts/find-delegatable.sh --from-triage triage-data.json --ai-ready

# Find issues ready for human assignment
./scripts/find-delegatable.sh --from-triage triage-data.json --needs-human
```

## Workflow

### AI Delegation Workflow

1. **Triage**: Run issue-triage to score issues
2. **Identify**: Find issues with delegation ≥ 4 and clarity ≥ 4
3. **Prepare**: Add `ai-ready` label (using issue-labeler skill)
4. **Delegate**: Use this skill to assign to Copilot Coding Agent
5. **Monitor**: Track progress of AI-created PRs

### Human Delegation Workflow

1. **Triage**: Run issue-triage to score issues  
2. **Identify**: Find issues with delegation ≤ 3 or needing design decisions
3. **Label**: Add appropriate labels (priority, effort, etc.)
4. **Assign**: Assign to appropriate team member based on expertise
5. **Track**: Monitor issue progress

## Examples

### Delegate to Copilot Coding Agent

```bash
./scripts/delegate-issue.sh --repo myorg/myrepo --issue 42 --to copilot
```

This will:
1. Verify the issue is suitable for AI (checks labels, clarity)
2. Add label: `ai-ready` if not present
3. Create a Copilot task or comment with delegation instructions
4. Output the task URL or confirmation

### Batch Delegate AI-Ready Issues

```bash
./scripts/batch-delegate.sh --repo myorg/myrepo \
  --from-triage triage-data.json \
  --filter "delegation>=4,clarity>=4" \
  --to copilot
```

### Find Issues to Delegate

```bash
./scripts/find-delegatable.sh --from-triage triage-data.json --ai-ready
```

Output:
```json
{
  "ai_ready": [
    {
      "issue": 123,
      "title": "Fix typo in README",
      "delegation_score": 5,
      "clarity_score": 5,
      "effort_score": 5,
      "recommendation": "Perfect for AI - trivial, crystal clear"
    },
    {
      "issue": 456,
      "title": "Add input validation to API endpoint",
      "delegation_score": 4,
      "clarity_score": 4,
      "effort_score": 4,
      "recommendation": "Good for AI - clear scope, may need minor clarification"
    }
  ],
  "total": 2
}
```

### Assign to Human Contributors

```bash
# Round-robin assignment
./scripts/batch-delegate.sh --repo myorg/myrepo \
  --issues "100,101,102,103" \
  --to "@alice,@bob"
```

Result:
- #100 → @alice
- #101 → @bob  
- #102 → @alice
- #103 → @bob

## LLM Integration

When analyzing triage data, output delegation recommendations:

```json
{
  "delegation_recommendations": [
    {
      "issue": 123,
      "delegate_to": "copilot",
      "confidence": "high",
      "scores": {
        "delegation": 5,
        "clarity": 5,
        "effort": 5
      },
      "rationale": "Trivial docs fix, exact change specified, perfect for AI",
      "context": "Update the version number in package.json from 1.0.0 to 1.0.1"
    },
    {
      "issue": 456,
      "delegate_to": "human",
      "confidence": "high", 
      "scores": {
        "delegation": 2,
        "clarity": 3,
        "effort": 2
      },
      "rationale": "Needs architectural decision, multiple valid approaches",
      "suggested_assignee": "Someone familiar with the auth system"
    }
  ]
}
```

Then execute:

```bash
# AI delegation
./scripts/delegate-issue.sh --repo owner/repo --issue 123 --to copilot \
  --context "Update the version number in package.json from 1.0.0 to 1.0.1"

# Human assignment (if you know the right person)
gh issue edit 456 --repo owner/repo --add-assignee alice
```

## Copilot Coding Agent Integration

When delegating to Copilot Coding Agent:

1. The script comments on the issue with a structured prompt
2. The comment follows Copilot's expected format for task creation
3. Include any additional context that helps scope the work

Example comment format:
```markdown
@copilot Please work on this issue.

## Context
- Focus on the specific files mentioned
- Follow existing code patterns
- Add tests for new functionality

## Acceptance Criteria
- [ ] Change implemented
- [ ] Tests pass
- [ ] Documentation updated if needed
```

## Delegation Decision Matrix

| Delegation Score | Clarity Score | Effort Score | Recommendation |
|-----------------|---------------|--------------|----------------|
| 5 | 5 | 4-5 | **AI Ready** - Delegate immediately |
| 4-5 | 4-5 | 1-3 | **AI with oversight** - May need review |
| 4-5 | 1-3 | any | **Needs clarification** - Ask questions first |
| 1-3 | any | any | **Human required** - Assign to contributor |

## Notes

- Always verify issues are truly AI-ready before delegating
- Provide additional context when the issue description is minimal
- AI delegation works best for:
  - Bug fixes with clear reproduction steps
  - Documentation updates
  - Refactoring with defined scope
  - Adding tests for existing code
  - Simple feature additions
- Human delegation is better for:
  - Architecture decisions
  - User experience design
  - Security-sensitive changes
  - Breaking changes
  - Features requiring stakeholder input
- Monitor AI-created PRs for quality and correctness
- The --dry-run flag shows what would happen without making changes
