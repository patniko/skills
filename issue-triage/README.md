# Issue Triage Skill

A GitHub Copilot CLI skill for fetching, analyzing, and prioritizing GitHub issues with an interactive dashboard.

## Features

- **Fetch issues** from any GitHub repository with pagination support
- **Automatic scoring** using heuristics (importance, urgency, clarity, effort, delegation)
- **Interactive dashboard** with 7 tabs of analytics and visualizations
- **Trend analysis** showing issue velocity, SLA performance, and historical patterns
- **Issue viewer** for detailed exploration and manual scoring

## Requirements

| Tool | Required | Purpose |
|------|----------|---------|
| `curl` | ✅ | Fetches data from GitHub API |
| `jq` | ✅ | Processes JSON data |
| `gh` | Optional | Required for private repos (authentication) |
| Modern browser | ✅ | For dashboard and viewer |

### Installing Dependencies

```bash
# macOS
brew install curl jq gh

# Ubuntu/Debian
sudo apt install curl jq
# gh CLI: https://github.com/cli/cli#installation

# Verify installation
curl --version && jq --version
```

## Quick Start

### 1. Fetch Issues

```bash
cd issue-triage

# Fetch all open issues from a public repo
./scripts/fetch-issues.sh owner/repo

# Fetch with limit
./scripts/fetch-issues.sh owner/repo --limit 100

# Fetch and open viewer immediately
./scripts/fetch-issues.sh owner/repo --view
```

### 2. View Dashboard

Open `dashboard.html` in your browser for analytics, or `viewer.html` for issue-by-issue exploration.

```bash
# macOS
open dashboard.html

# Linux
xdg-open dashboard.html

# Or just double-click the HTML file
```

### 3. Using with Copilot CLI

The skill is designed to be invoked via Copilot CLI:

```bash
# From any directory with the skill installed
copilot "run issue-triage on owner/repo"
```

## Dashboard Tabs

| Tab | Description |
|-----|-------------|
| **Overview** | Key stats, critical issues, priority distribution, quick wins |
| **📈 Trends** | Volume over time, SLA gauges, velocity metrics, monthly breakdown |
| **Health & Hygiene** | Age distribution, label quality, stale issues, unassigned backlog |
| **Prioritization** | Top priority issues, delegatable items, enterprise issues |
| **Technical Debt** | Security issues, repro quality, needs-info, potential duplicates |
| **Engagement** | Comments, contributors, bugs vs features |
| **Insights** | Automated recommendations, action items, issue clusters |

## Scoring System

Issues are scored on 5 dimensions (1-5 scale):

| Dimension | Description |
|-----------|-------------|
| **Importance** | Impact on project success (5 = critical security/data issue) |
| **Urgency** | Time sensitivity (5 = production down) |
| **Clarity** | How well-defined (5 = clear repro, acceptance criteria) |
| **Effort** | Estimated work (5 = trivial fix, 1 = major project) |
| **Delegation** | AI/junior suitability (5 = perfect for automation) |

### Priority Formula

```
Priority = (Importance × 3) + (Urgency × 2.5) + (Clarity × 1.5) + (Effort × 1.5) + (Delegation × 1.5)
```

- **High Priority**: ≥ 30
- **Medium Priority**: 20-29  
- **Low Priority**: < 20

## File Structure

```
issue-triage/
├── README.md           # This file
├── SKILL.md            # Skill metadata for Copilot CLI
├── dashboard.html      # Analytics dashboard (7 tabs)
├── viewer.html         # Issue-by-issue viewer with scoring
├── scripts/
│   └── fetch-issues.sh # Data fetching script with pagination
└── triage-data.json    # Generated data (auto-created, git-ignored)
```

## Script Options

```bash
./scripts/fetch-issues.sh [owner/repo] [options]

Options:
  --limit N       Limit to N issues (default: fetch all)
  --output FILE   Output to FILE (default: triage-data.json)
  --view          Open viewer after fetching
```

## Examples

### Triage a Large Backlog

```bash
# Fetch all issues
./scripts/fetch-issues.sh microsoft/vscode

# Open dashboard for analysis
open dashboard.html
```

### Focus on Recent Issues

```bash
# Fetch last 50 issues
./scripts/fetch-issues.sh owner/repo --limit 50 --view
```

### Private Repository

```bash
# Authenticate first
gh auth login

# Then fetch (script uses gh for auth if available)
./scripts/fetch-issues.sh my-org/private-repo
```

## API Rate Limits

- **Unauthenticated**: 60 requests/hour
- **Authenticated (gh CLI)**: 5,000 requests/hour

For large repos (1000+ issues), authenticate with `gh auth login` first.

## Tips

1. **Start with the Trends tab** to understand volume and velocity
2. **Check SLA gauges** to see triage health at a glance
3. **Use Insights tab** for automated recommendations
4. **Filter by "enterprise"** in Prioritization for customer-impacting issues
5. **Export from viewer** to save your manual scoring work

## Troubleshooting

### "jq: command not found"
Install jq: `brew install jq` or `apt install jq`

### "API rate limit exceeded"
Authenticate with GitHub: `gh auth login`

### Dashboard shows no data
Ensure `triage-data.json` exists in the same directory as `dashboard.html`

### Private repo returns empty
Run `gh auth login` and ensure your token has `repo` scope

## License

MIT
