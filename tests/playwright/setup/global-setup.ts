import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  console.log('🚀 Starting global test setup...');
  
  // Launch browser for setup
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();
  
  try {
    // Wait for Flutter web app to be ready
    console.log('📱 Waiting for Flutter web app...');
    await page.goto('http://localhost:8080');
    
    // Wait for Flutter to finish loading (look for Flutter elements)
    await page.waitForSelector('flt-glass-pane', { 
      timeout: 60000,
      state: 'attached'  // Just wait for element to be in DOM, not necessarily visible
    });
    
    // Give Flutter more time to initialize
    await page.waitForTimeout(3000);
    
    console.log('✅ Flutter app loaded successfully');
    
    // Setup test data if needed
    await setupTestData(page);
    
  } catch (error) {
    console.error('❌ Global setup failed:', error);
    throw error;
  } finally {
    await context.close();
    await browser.close();
  }
  
  console.log('✅ Global test setup complete');
}

async function setupTestData(page: any) {
  // This would set up any test data needed for the tests
  // For example, mock API responses, seed data, etc.
  console.log('📊 Setting up test data...');
  
  // Mock external API calls
  await page.route('**/search.json', route => {
    route.fulfill({
      contentType: 'application/json',
      body: JSON.stringify({
        docs: [
          {
            key: '/works/OL123456W',
            title: 'Test Book Title',
            author_name: ['Test Author'],
            cover_i: 123456,
            first_publish_year: 1900,
            ia: ['test-book-archive-id']
          }
        ]
      })
    });
  });
  
  console.log('✅ Test data setup complete');
}

export default globalSetup;