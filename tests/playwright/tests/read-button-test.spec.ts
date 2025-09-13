import { test, expect } from '@playwright/test';

test.describe('Read Button Test', () => {
  test('Test Read button navigation from book details', async ({ page }) => {
    // Go to the Flutter app
    await page.goto('http://localhost:3000');
    
    // Wait for Flutter to load
    await page.waitForSelector('flt-glass-pane', { timeout: 10000 });
    await page.waitForTimeout(2000);
    
    console.log('🔍 Testing Read button functionality...');
    
    // Take a screenshot to see current state
    await page.screenshot({ path: 'read-button-test-start.png', fullPage: true });
    
    // Try to navigate to a book details page directly
    await page.goto('http://localhost:3000/#/book/alice-wonderland');
    await page.waitForTimeout(3000);
    
    // Take screenshot of book details
    await page.screenshot({ path: 'book-details-page.png', fullPage: true });
    
    // Look for Read button and try to click it
    const readButton = page.locator('text=Read');
    const isVisible = await readButton.isVisible();
    console.log(`📖 Read button visible: ${isVisible}`);
    
    if (isVisible) {
      const isEnabled = await readButton.isEnabled();
      console.log(`📖 Read button enabled: ${isEnabled}`);
      
      if (isEnabled) {
        await readButton.click();
        await page.waitForTimeout(2000);
        
        // Check if we navigated to reader
        const currentUrl = page.url();
        console.log(`🌐 Current URL after click: ${currentUrl}`);
        
        // Take screenshot of result
        await page.screenshot({ path: 'after-read-click.png', fullPage: true });
        
        // Check if we're on reader page
        if (currentUrl.includes('/reader/')) {
          console.log('✅ Read button navigation successful!');
        } else {
          console.log('❌ Read button did not navigate to reader');
        }
      } else {
        console.log('❌ Read button is disabled');
      }
    } else {
      console.log('❌ Read button not found');
    }
  });
});