import { test, expect } from '@playwright/test';

test.describe('Read Button with Mock Books', () => {
  test('Test Read button with mock downloaded books', async ({ page }) => {
    console.log('🔍 Testing Read button with mock books...');
    
    // Step 1: Go to the Flutter app  
    await page.goto('http://localhost:3000');
    await page.waitForSelector('flt-glass-pane', { timeout: 15000 });
    await page.waitForTimeout(3000);
    
    console.log('📱 App loaded, checking library...');
    await page.screenshot({ path: 'library-with-mock-books.png', fullPage: true });
    
    // Step 2: Click on the first book in library
    console.log('📖 Clicking on first book...');
    await page.click('flt-glass-pane', { position: { x: 400, y: 300 } });
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: 'book-details-with-mock.png', fullPage: true });
    
    // Step 3: Check current URL to see if we're on book details
    const currentUrl = page.url();
    console.log(`🌐 Current URL after book click: ${currentUrl}`);
    
    if (currentUrl.includes('/book/')) {
      console.log('✅ Successfully navigated to book details');
      
      // Step 4: Look for and click Read button
      console.log('📖 Looking for Read button...');
      
      const pageContent = await page.content();
      const hasReadText = pageContent.includes('Read');
      console.log(`📄 Page contains "Read" text: ${hasReadText}`);
      
      if (hasReadText) {
        // Try clicking in areas where Read button should be
        const readButtonAreas = [
          { x: 350, y: 450, name: 'read-button-center' },
          { x: 320, y: 480, name: 'read-button-left' },
          { x: 380, y: 480, name: 'read-button-right' },
          { x: 350, y: 520, name: 'read-button-lower' },
        ];
        
        for (const area of readButtonAreas) {
          console.log(`👆 Trying Read button at (${area.x}, ${area.y})`);
          await page.click('flt-glass-pane', { position: area });
          await page.waitForTimeout(1500);
          
          const newUrl = page.url();
          console.log(`🌐 URL after Read click: ${newUrl}`);
          
          if (newUrl.includes('/reader/')) {
            console.log('✅ SUCCESS: Read button navigated to reader!');
            await page.screenshot({ path: 'reader-page-success.png', fullPage: true });
            
            // Verify reader interface loaded
            await page.waitForTimeout(2000);
            const readerContent = await page.content();
            const hasChapterContent = readerContent.includes('Chapter') || readerContent.includes('Alice');
            console.log(`📚 Reader has chapter content: ${hasChapterContent}`);
            
            return;
          }
        }
        
        console.log('❌ Read button found but clicking did not navigate');
      } else {
        console.log('❌ Read button text not found on page');
      }
    } else {
      console.log('❌ Could not navigate to book details page');
    }
    
    await page.screenshot({ path: 'read-test-final-state.png', fullPage: true });
  });
});