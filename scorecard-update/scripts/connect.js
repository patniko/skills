const { chromium } = require('playwright');

async function connectToChrome() {
  try {
    // Connect to Chrome running with --remote-debugging-port=9222
    const browser = await chromium.connectOverCDP('http://localhost:9222');
    console.log('Connected to Chrome');
    
    // Get existing contexts (your logged-in session)
    const contexts = browser.contexts();
    if (contexts.length === 0) {
      throw new Error('No browser contexts found. Make sure Chrome is running with tabs open.');
    }
    
    const context = contexts[0];
    console.log(`Found ${context.pages().length} open tabs`);
    
    return { browser, context };
  } catch (error) {
    if (error.message.includes('ECONNREFUSED')) {
      console.error(`
Error: Cannot connect to Chrome.

Please start Chrome with remote debugging:

  /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --remote-debugging-port=9222

Then run this script again.
`);
    } else {
      console.error('Connection error:', error.message);
    }
    process.exit(1);
  }
}

module.exports = { connectToChrome };

// If run directly, test the connection
if (require.main === module) {
  (async () => {
    const { browser, context } = await connectToChrome();
    const pages = context.pages();
    console.log('\nOpen tabs:');
    for (const page of pages) {
      console.log(`  - ${page.url()}`);
    }
    await browser.close();
  })();
}
