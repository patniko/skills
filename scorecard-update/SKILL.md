---
name: scorecard-update
description: Review Azure Data Explorer dashboards for Copilot CLI metrics and update Google Sheets scorecard. Connects to existing Chrome session for authentication.
license: MIT
compatibility: Requires Node.js, Playwright, and Chrome running with --remote-debugging-port=9222
metadata:
  author: patrick
  version: "1.0"
allowed-tools: bash node
---

# Scorecard Update

Review Copilot CLI metrics from Azure Data Explorer dashboards and update the Google Sheets scorecard.

## Prerequisites

Before using this skill, start Chrome with remote debugging:

```bash
# macOS
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222

# Then log into your Azure and Google accounts in that browser session
```

## Workflow

This skill follows a **review-before-update** workflow:

1. **Read scorecard** → Identify which Copilot CLI metrics need updating
2. **Capture dashboards** → Screenshot and extract data from Azure Data Explorer
3. **Generate summary** → Create a review document with proposed updates
4. **Human review** → You approve/modify the proposed changes
5. **Update scorecard** → Apply approved changes to Google Sheets

## Data Sources

### Dashboards (Azure Data Explorer)

| Dashboard | Purpose |
|-----------|---------|
| [Launch Metrics](https://dataexplorer.azure.com/dashboards/28614488-f863-4c1e-a47f-9d8a755005d8?p-_launchTime=v-2025-09-25T17-00-00.0000000Z#deba6bb9-3e80-452f-8893-fa511205aeac) | Metrics since launch date |
| [30-Day Trends](https://dataexplorer.azure.com/dashboards/28614488-f863-4c1e-a47f-9d8a755005d8?p-_startTime=30days&p-_endTime=now#ae5820e9-0ab3-433b-91ce-39931599c6f5) | Rolling 30-day window |
| [Overview](https://dataexplorer.azure.com/dashboards/28614488-f863-4c1e-a47f-9d8a755005d8#76f1540e-7169-458f-a6d1-b8210fdb8099) | General dashboard view |

### Scorecard (Google Sheets)

[Copilot CLI Scorecard](https://docs.google.com/spreadsheets/d/1KYe_EjFftKrKKu9va6kv4YZ2ZCAaY5uTvsjfxDfxsFY/edit?gid=1633827731#gid=1633827731)

## Quick Start

```bash
# 1. Ensure Chrome is running with debugging port (see Prerequisites)

# 2. Install dependencies (first time only)
cd scorecard-update && npm install

# 3. Run the workflow
node scripts/workflow.js
```

## Step-by-Step Instructions

### Step 1: Read the Scorecard

Connect to Chrome and navigate to the scorecard to identify metrics that need updating:

```javascript
// The script will:
// 1. Open the scorecard
// 2. Find the Copilot CLI section
// 3. List metrics and their current values
// 4. Identify which need updating (blank, outdated, etc.)
```

### Step 2: Capture Dashboard Data

For each dashboard, the script will:
1. Navigate to the URL
2. Wait for charts to render
3. Take a screenshot
4. Extract visible metrics/numbers from the page

### Step 3: Review Summary

Before any updates, you'll receive a summary like:

```
## Proposed Scorecard Updates

| Metric | Current Value | New Value | Source |
|--------|---------------|-----------|--------|
| DAU    | 1,234         | 1,456     | 30-Day Dashboard |
| ...    | ...           | ...       | ... |

Screenshots saved to: ./screenshots/

Please review and confirm before updating.
```

### Step 4: Update Scorecard

After your approval, the script navigates to the scorecard and updates the specified cells.

## Scripts

| Script | Purpose |
|--------|---------|
| `workflow.js` | Main orchestrator - runs full workflow |
| `connect.js` | Connect to Chrome debugging session |
| `capture-dashboards.js` | Screenshot and extract dashboard data |
| `read-scorecard.js` | Read current scorecard values |
| `update-scorecard.js` | Write updates to scorecard |

## Output Files

```
scorecard-update/
├── screenshots/           # Dashboard screenshots (timestamped)
├── data/
│   ├── scorecard-current.json   # Current scorecard state
│   ├── dashboard-data.json      # Extracted dashboard metrics
│   └── proposed-updates.json    # Summary for review
└── summaries/
    └── YYYY-MM-DD-summary.md    # Human-readable summary
```

## Notes

- All changes require human approval before applying
- Screenshots provide audit trail of data sources
- The script waits for Azure dashboards to fully render (they can be slow)
- If a metric can't be automatically extracted, it will be flagged for manual review
