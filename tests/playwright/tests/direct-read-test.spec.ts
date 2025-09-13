import { test, expect } from '@playwright/test';

test.describe('Direct Read Button Test', () => {
  test('Test Read button by going directly to book details', async ({ page }) => {
    console.log('🔍 Testing Read button by direct navigation...');
    
    // Go directly to book details for alice-wonderland (one of our mock books)
    await page.goto('http://localhost:3000/#/book/alice-wonderland');
    await page.waitForSelector('flt-glass-pane', { timeout: 15000 });
    await page.waitForTimeout(5000);
    
    console.log('📱 Navigated directly to book details...');
    await page.screenshot({ path: 'direct-book-details.png', fullPage: true });
    
    // Check if we see book details or "Book not found"
    const pageContent = await page.content();
    const hasBookNotFound = pageContent.includes('Book not found');
    const hasReadButton = pageContent.includes('Read');
    
    console.log(`❌ Shows "Book not found": ${hasBookNotFound}`);
    console.log(`📖 Has "Read" text: ${hasReadButton}`);
    
    if (hasBookNotFound) {
      console.log('❌ Issue confirmed: Book not found even with mock books');
      console.log('🔍 This means the book lookup in _findBook() is not finding our mock books');
    }
    
    // Let's try clicking the Read button anyway if it exists
    if (hasReadButton && !hasBookNotFound) {
      console.log('📖 Found Read button, testing navigation...');
      
      // Try clicking where Read button should be
      await page.click('flt-glass-pane', { position: { x: 350, y: 450 } });
      await page.waitForTimeout(2000);
      
      const newUrl = page.url();
      console.log(`🌐 URL after Read click: ${newUrl}`);
      
      if (newUrl.includes('/reader/')) {
        console.log('✅ Read button works! Navigated to reader');
        await page.screenshot({ path: 'reader-loaded.png', fullPage: true });
      } else {
        console.log('❌ Read button did not navigate');
      }
    }
  });
});