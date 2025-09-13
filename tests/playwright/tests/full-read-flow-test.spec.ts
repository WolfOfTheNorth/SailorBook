import { test, expect } from '@playwright/test';

test.describe('Full Read Flow Test', () => {
  test('Test complete flow: Search → Download → Library → Book Details → Read', async ({ page }) => {
    console.log('🔍 Testing complete read flow as user described...');
    
    // Step 1: Go to the Flutter app  
    await page.goto('http://localhost:3000');
    await page.waitForSelector('flt-glass-pane', { timeout: 15000 });
    await page.waitForTimeout(3000);
    
    console.log('📱 App loaded, taking screenshot...');
    await page.screenshot({ path: 'step1-app-loaded.png', fullPage: true });
    
    // Step 2: Search for book
    console.log('🔍 Step 2: Searching for book...');
    // Try clicking on search tab
    await page.click('flt-glass-pane', { position: { x: 300, y: 150 } });
    await page.waitForTimeout(1000);
    
    // Type search query
    await page.keyboard.type('alice');
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'step2-after-search.png', fullPage: true });
    
    // Step 3: Download a book
    console.log('📥 Step 3: Looking for download button...');
    // Try to find and click download button
    await page.click('flt-glass-pane', { position: { x: 400, y: 400 } });
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: 'step3-after-download-attempt.png', fullPage: true });
    
    // Step 4: Go to library
    console.log('📚 Step 4: Going to library...');
    await page.click('flt-glass-pane', { position: { x: 100, y: 150 } });
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'step4-library-view.png', fullPage: true });
    
    // Step 5: Click on a book
    console.log('📖 Step 5: Clicking on book...');
    await page.click('flt-glass-pane', { position: { x: 400, y: 300 } });
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: 'step5-book-details.png', fullPage: true });
    
    // Step 6: Look for Read button
    console.log('📖 Step 6: Looking for Read button...');
    
    // Check current URL
    const currentUrl = page.url();
    console.log(`🌐 Current URL: ${currentUrl}`);
    
    // Try to find text "Read" on the page
    const pageContent = await page.content();
    const hasReadText = pageContent.includes('Read');
    console.log(`📄 Page contains "Read" text: ${hasReadText}`);
    
    if (hasReadText) {
      console.log('📖 Found Read text, attempting to click...');
      // Try clicking in different areas where Read button might be
      const clickAreas = [
        { x: 320, y: 450, name: 'read-button-area-1' },
        { x: 350, y: 480, name: 'read-button-area-2' },
        { x: 300, y: 520, name: 'read-button-area-3' },
      ];
      
      for (const area of clickAreas) {
        console.log(`👆 Trying to click Read button at (${area.x}, ${area.y})`);
        await page.click('flt-glass-pane', { position: area });
        await page.waitForTimeout(1000);
        
        const newUrl = page.url();
        console.log(`🌐 URL after click: ${newUrl}`);
        
        if (newUrl.includes('/reader/')) {
          console.log('✅ Successfully navigated to reader!');
          await page.screenshot({ path: 'step6-reader-success.png', fullPage: true });
          return;
        }
      }
    }
    
    console.log('❌ Read button click did not work');
    await page.screenshot({ path: 'step6-read-failed.png', fullPage: true });
  });
});