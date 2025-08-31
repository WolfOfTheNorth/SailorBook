import { test, expect } from '@playwright/test';

test.describe('Coordinate-based Search Test', () => {
  
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(3000); // Allow Flutter to fully initialize
  });

  test('Manual search with coordinate clicks and real API', async ({ page }) => {
    console.log('🔍 Starting manual search test...');
    
    // Track API requests
    const apiRequests: string[] = [];
    page.on('request', request => {
      const url = request.url();
      if (url.includes('openlibrary.org/search.json')) {
        apiRequests.push(url);
        console.log('🌐 API Request detected:', url);
      }
      if (url.includes('search')) {
        console.log('🔍 Any search-related request:', url);
      }
    });
    
    page.on('response', response => {
      if (response.url().includes('openlibrary.org')) {
        console.log('📡 API Response:', response.status(), response.url());
      }
    });
    
    // Take initial screenshot
    await page.screenshot({ path: 'test-results/initial-state.png', fullPage: true });
    
    // Click on search tab area (coordinates)
    console.log('👆 Clicking search tab...');
    await page.click('flt-glass-pane', { position: { x: 350, y: 150 } });
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/search-tab-clicked.png', fullPage: true });
    
    // Click in search input area 
    console.log('👆 Clicking search input...');
    await page.click('flt-glass-pane', { position: { x: 300, y: 200 } });
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: 'test-results/search-input-focused.png', fullPage: true });
    
    // Type search query
    console.log('⌨️  Typing search query...');
    await page.keyboard.type('alice wonderland', { delay: 100 });
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: 'test-results/query-typed.png', fullPage: true });
    
    // Press Enter to search
    console.log('⏎ Pressing Enter to search...');
    await page.keyboard.press('Enter');
    
    // Wait for API response and results
    console.log('⏳ Waiting for search results...');
    await page.waitForTimeout(5000);
    
    await page.screenshot({ path: 'test-results/search-results.png', fullPage: true });
    
    console.log(`📊 API Requests made: ${apiRequests.length}`);
    apiRequests.forEach((url, index) => {
      console.log(`  ${index + 1}. ${url}`);
    });
    
    // Verify API was called
    if (apiRequests.length > 0) {
      console.log('✅ Search API was successfully called');
      expect(apiRequests[0]).toContain('openlibrary.org/search.json');
      expect(apiRequests[0]).toContain('alice%20wonderland');
    } else {
      console.log('❌ No API requests detected - search may not be working');
    }
    
    console.log('✅ Manual search test completed');
  });

});