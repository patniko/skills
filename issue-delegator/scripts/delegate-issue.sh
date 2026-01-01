#!/usr/bin/env bash
#
# delegate-issue.sh - Delegate a GitHub issue to Copilot or a human contributor
#
# Usage:
#   ./delegate-issue.sh --repo owner/repo --issue 123 --to copilot
#   ./delegate-issue.sh --repo owner/repo --issue 123 --to @username
#   ./delegate-issue.sh --repo owner/repo --issue 123 --to copilot --context "Additional instructions"
#

set -euo pipefail

REPO=""
ISSUE=""
DELEGATE_TO=""
CONTEXT=""
DRY_RUN=false

usage() {
    echo "Usage: $0 --repo OWNER/REPO --issue NUMBER --to TARGET [options]"
    echo ""
    echo "Options:"
    echo "  --repo      Repository in owner/repo format (required)"
    echo "  --issue     Issue number (required)"
    echo "  --to        Delegate target: 'copilot' or '@username' (required)"
    echo "  --context   Additional context or instructions for the delegate"
    echo "  --dry-run   Preview without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 --repo myorg/myrepo --issue 42 --to copilot"
    echo "  $0 --repo myorg/myrepo --issue 42 --to @alice"
    echo "  $0 --repo myorg/myrepo --issue 42 --to copilot --context 'Focus on the API layer'"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO="$2"
            shift 2
            ;;
        --issue)
            ISSUE="$2"
            shift 2
            ;;
        --to)
            DELEGATE_TO="$2"
            shift 2
            ;;
        --context)
            CONTEXT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$REPO" || -z "$ISSUE" || -z "$DELEGATE_TO" ]]; then
    echo "Error: --repo, --issue, and --to are required"
    usage
fi

echo "Delegating issue #$ISSUE in $REPO to $DELEGATE_TO"

if [[ "$DELEGATE_TO" == "copilot" ]]; then
    # Delegation to Copilot Coding Agent
    # Add ai-ready label and create a comment that Copilot can act on
    
    COMMENT="@github-copilot Please work on this issue.

## Instructions
Review the issue description and implement the requested changes.
"

    if [[ -n "$CONTEXT" ]]; then
        COMMENT="$COMMENT
## Additional Context
$CONTEXT
"
    fi

    COMMENT="$COMMENT
## Guidelines
- Follow existing code patterns and conventions
- Add tests for new functionality
- Update documentation if needed
- Keep changes focused and minimal
"

    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "[DRY RUN] Would execute:"
        echo "  gh issue edit $ISSUE --repo $REPO --add-label 'ai-ready'"
        echo "  gh issue comment $ISSUE --repo $REPO --body '...'"
        echo ""
        echo "Comment would be:"
        echo "---"
        echo "$COMMENT"
        echo "---"
    else
        # Add ai-ready label
        gh label create "ai-ready" --repo "$REPO" 2>/dev/null || true
        gh issue edit "$ISSUE" --repo "$REPO" --add-label "ai-ready"
        
        # Add comment to trigger Copilot
        gh issue comment "$ISSUE" --repo "$REPO" --body "$COMMENT"
        
        echo "✓ Issue #$ISSUE delegated to Copilot"
        echo "  Label added: ai-ready"
        echo "  Comment added with Copilot instructions"
    fi

elif [[ "$DELEGATE_TO" == @* ]]; then
    # Delegation to human contributor
    USERNAME="${DELEGATE_TO#@}"
    
    if [[ "$DRY_RUN" == true ]]; then
        echo ""
        echo "[DRY RUN] Would execute:"
        echo "  gh issue edit $ISSUE --repo $REPO --add-assignee $USERNAME"
        if [[ -n "$CONTEXT" ]]; then
            echo "  gh issue comment $ISSUE --repo $REPO --body '...'"
        fi
    else
        # Assign the issue
        gh issue edit "$ISSUE" --repo "$REPO" --add-assignee "$USERNAME"
        
        # Add context comment if provided
        if [[ -n "$CONTEXT" ]]; then
            COMMENT="@$USERNAME This issue has been assigned to you.

## Context
$CONTEXT"
            gh issue comment "$ISSUE" --repo "$REPO" --body "$COMMENT"
        fi
        
        echo "✓ Issue #$ISSUE assigned to @$USERNAME"
    fi

else
    echo "Error: --to must be 'copilot' or '@username'"
    exit 1
fi
