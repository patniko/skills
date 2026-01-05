const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const DASHBOARDS = [
  {
    name: 'launch-metrics',
    url: 'https://dataexplorer.azure.com/dashboards/28614488-f863-4c1e-a47f-9d8a755005d8?p-_launchTime=v-2025-09-25T17-00-00.0000000Z#deba6bb9-3e80-452f-8893-fa511205aeac',
    description: 'Metrics since launch date'
  },
  {
    name: '30-day-trends', 
    url: 'https://dataexplorer.azure.com/dashboards/28614488-f863-4c1e-a47f-9d8a755005d8?p-_startTime=30days&p-_endTime=now#ae5820e9-0ab3-433b-91ce-39931599c6f5',
    description: 'Rolling 30-day window'
  },
  {
    name: 'overview',
    url: 'https://dataexplorer.azure.com/dashboards/28614488-f863-4c1e-a47f-9d8a755005d8#76f1540e-7169-458f-a6d1-b8210fdb8099',
    description: 'General dashboard view'
  }
];

const SCORECARD_URL = 'https://docs.google.com/spreadsheets/d/1KYe_EjFftKrKKu9va6kv4YZ2ZCAaY5uTvsjfxDfxsFY/edit?gid=1633827731#gid=1633827731';

const DIRS = {
  screenshots: path.join(__dirname, '..', 'screenshots'),
  data: path.join(__dirname, '..', 'data'),
  summaries: path.join(__dirname, '..', 'summaries')
};

async function ensureDirectories() {
  for (const dir of Object.values(DIRS)) {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }
}

async function connectToChrome() {
  try {
    const browser = await chromium.connectOverCDP('http://localhost:9222');
    console.log('✓ Connected to Chrome');
    const contexts = browser.contexts();
    if (contexts.length === 0) {
      throw new Error('No browser contexts found');
    }
    return { browser, context: contexts[0] };
  } catch (error) {
    if (error.message.includes('ECONNREFUSED')) {
      console.error(`
✗ Cannot connect to Chrome.

Start Chrome with remote debugging:

  /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --remote-debugging-port=9222
`);
    }
    process.exit(1);
  }
}

async function captureScorecard(context, timestamp) {
  console.log('\n📊 Reading scorecard...');
  const page = await context.newPage();
  
  try {
    await page.goto(SCORECARD_URL, { waitUntil: 'networkidle', timeout: 60000 });
    await page.waitForTimeout(3000); // Let sheets fully render
    
    const screenshotPath = path.join(DIRS.screenshots, `scorecard-${timestamp}.png`);
    await page.screenshot({ path: screenshotPath, fullPage: true });
    console.log(`  ✓ Screenshot saved: ${screenshotPath}`);
    
    // Try to extract visible cell data
    const title = await page.title();
    console.log(`  ✓ Scorecard: ${title}`);
    
    return { 
      url: SCORECARD_URL,
      screenshot: screenshotPath,
      title 
    };
  } finally {
    await page.close();
  }
}

async function captureDashboard(context, dashboard, timestamp) {
  console.log(`\n📈 Capturing: ${dashboard.name}...`);
  const page = await context.newPage();
  
  try {
    await page.goto(dashboard.url, { waitUntil: 'networkidle', timeout: 90000 });
    
    // Azure Data Explorer dashboards need time to render charts
    console.log('  ⏳ Waiting for charts to render...');
    await page.waitForTimeout(10000);
    
    const screenshotPath = path.join(DIRS.screenshots, `${dashboard.name}-${timestamp}.png`);
    await page.screenshot({ path: screenshotPath, fullPage: true });
    console.log(`  ✓ Screenshot saved: ${screenshotPath}`);
    
    return {
      name: dashboard.name,
      url: dashboard.url,
      description: dashboard.description,
      screenshot: screenshotPath
    };
  } finally {
    await page.close();
  }
}

async function generateSummary(scorecardData, dashboardData, timestamp) {
  const summaryPath = path.join(DIRS.summaries, `${timestamp}-summary.md`);
  
  const summary = `# Scorecard Update Summary

Generated: ${new Date().toISOString()}

## Scorecard

- **URL**: ${scorecardData.url}
- **Screenshot**: ${scorecardData.screenshot}

## Dashboards Captured

${dashboardData.map(d => `### ${d.name}
- **Description**: ${d.description}
- **URL**: ${d.url}
- **Screenshot**: ${d.screenshot}
`).join('\n')}

## Next Steps

1. Review the screenshots in \`screenshots/\`
2. Identify metrics to update in the scorecard
3. Manually update or use \`update-scorecard.js\` with specific values

## Notes

- Azure Data Explorer dashboards were given 10 seconds to render
- If charts appear incomplete, re-run or increase wait time
- All screenshots are timestamped for audit trail
`;

  fs.writeFileSync(summaryPath, summary);
  console.log(`\n📝 Summary saved: ${summaryPath}`);
  return summaryPath;
}

async function main() {
  const timestamp = new Date().toISOString().split('T')[0];
  
  console.log('🚀 Scorecard Update Workflow\n');
  console.log('=' .repeat(50));
  
  await ensureDirectories();
  const { browser, context } = await connectToChrome();
  
  try {
    // Step 1: Capture scorecard
    const scorecardData = await captureScorecard(context, timestamp);
    
    // Step 2: Capture dashboards
    const dashboardData = [];
    for (const dashboard of DASHBOARDS) {
      const data = await captureDashboard(context, dashboard, timestamp);
      dashboardData.push(data);
    }
    
    // Step 3: Generate summary
    const summaryPath = await generateSummary(scorecardData, dashboardData, timestamp);
    
    // Save data for later use
    const dataPath = path.join(DIRS.data, `${timestamp}-capture.json`);
    fs.writeFileSync(dataPath, JSON.stringify({
      timestamp,
      scorecard: scorecardData,
      dashboards: dashboardData
    }, null, 2));
    
    console.log('\n' + '='.repeat(50));
    console.log('✅ Workflow complete!\n');
    console.log('Next: Review screenshots and summary, then update scorecard.');
    
  } finally {
    await browser.close();
  }
}

main().catch(console.error);
