import { test, expect } from '@playwright/test';

test.describe('Direct Reader Test', () => {
  test('Test reader page by direct navigation', async ({ page }) => {
    console.log('🔍 Testing reader page directly...');
    
    // Go directly to reader page
    await page.goto('http://localhost:3000/#/reader/alice-wonderland');
    await page.waitForSelector('flt-glass-pane', { timeout: 15000 });
    await page.waitForTimeout(5000);
    
    console.log('📱 Navigated directly to reader page...');
    await page.screenshot({ path: 'direct-reader-test.png', fullPage: true });
    
    // Check if reader loaded
    const pageContent = await page.content();
    const hasChapterContent = pageContent.includes('Chapter') || pageContent.includes('Alice');
    const hasReaderElements = pageContent.includes('Reading') || pageContent.includes('reader');
    
    console.log(`📚 Has chapter content: ${hasChapterContent}`);
    console.log(`📖 Has reader elements: ${hasReaderElements}`);
    
    const currentUrl = page.url();
    console.log(`🌐 Current URL: ${currentUrl}`);
    
    if (currentUrl.includes('/reader/')) {
      console.log('✅ Successfully on reader page!');
      
      // Test chapter navigation if visible
      if (pageContent.includes('Chapter')) {
        console.log('📖 Testing chapter navigation...');
        
        // Try clicking next chapter button
        await page.click('flt-glass-pane', { position: { x: 600, y: 700 } });
        await page.waitForTimeout(1000);
        await page.screenshot({ path: 'after-chapter-nav.png', fullPage: true });
      }
    } else {
      console.log('❌ Not on reader page');
    }
  });
});