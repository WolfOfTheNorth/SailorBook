import { test, expect } from '@playwright/test';

test.describe('Smoke Test - Basic App Functionality', () => {
  
  test('App loads and basic elements are present', async ({ page }) => {
    await page.goto('/');
    
    // Wait for Flutter to load
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(3000);
    
    // Basic app verification
    await expect(page).toHaveTitle(/Public-Domain Reader/);
    
    // Take screenshot for manual validation
    await page.screenshot({ 
      path: 'test-results/smoke-test-app-loaded.png',
      fullPage: true 
    });
    
    console.log('✅ App loads successfully');
  });
  
  test('API connectivity check', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    
    // Test API call manually by monitoring network
    let apiCallMade = false;
    page.on('request', request => {
      if (request.url().includes('openlibrary.org')) {
        apiCallMade = true;
        console.log('✅ API call detected:', request.url());
      }
    });
    
    // Try to trigger search by clicking and typing
    await page.click('flt-glass-pane', { position: { x: 400, y: 150 } });
    await page.waitForTimeout(1000);
    await page.keyboard.type('test');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(5000);
    
    console.log(`📡 API call made: ${apiCallMade}`);
  });
});