import { test, expect } from '@playwright/test';

/**
 * Debug test to understand what's happening with the reader
 */

test.describe('Debug Reader Test', () => {
  
  test('debug what elements are available', async ({ page }) => {
    console.log('🔍 Debugging available elements...');

    await page.goto('http://localhost:3000');
    await page.waitForLoadState('networkidle');
    
    // Take a screenshot
    await page.screenshot({ path: 'debug-home.png', fullPage: true });
    console.log('📸 Screenshot saved as debug-home.png');

    // List all elements with test-id attributes
    const testElements = await page.$$('[data-test-id]');
    console.log(`Found ${testElements.length} elements with test-id attributes`);
    
    for (let i = 0; i < testElements.length; i++) {
      const element = testElements[i];
      const testId = await element.getAttribute('data-test-id');
      const tagName = await element.evaluate(el => el.tagName.toLowerCase());
      const isVisible = await element.isVisible();
      console.log(`  ${i+1}. ${tagName}[data-test-id="${testId}"] - visible: ${isVisible}`);
    }

    // Check for common Flutter elements
    const flutterViewport = page.locator('flt-flutter-view');
    if (await flutterViewport.count() > 0) {
      console.log('✅ Found flt-flutter-view element');
    }

    const flutterGlass = page.locator('flt-glass-pane');
    if (await flutterGlass.count() > 0) {
      console.log('✅ Found flt-glass-pane element');
      console.log(`Glass pane visible: ${await flutterGlass.isVisible()}`);
    }

    // Try to find any Flutter content
    const bodyContent = await page.locator('body').innerHTML();
    console.log('📄 Body content preview:', bodyContent.substring(0, 500));

    // Wait a bit and try again
    await page.waitForTimeout(5000);
    
    const testElementsAfterWait = await page.$$('[data-test-id]');
    console.log(`After 5s wait: Found ${testElementsAfterWait.length} elements with test-id attributes`);

    // Try direct navigation to reader
    console.log('🎯 Trying direct navigation to reader...');
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');
    
    await page.screenshot({ path: 'debug-reader.png', fullPage: true });
    console.log('📸 Reader screenshot saved as debug-reader.png');

    // Check for reader elements
    const readerElements = await page.$$('[data-test-id*="reader"]');
    console.log(`Found ${readerElements.length} reader-related elements`);
    
    for (let i = 0; i < readerElements.length; i++) {
      const element = readerElements[i];
      const testId = await element.getAttribute('data-test-id');
      const isVisible = await element.isVisible();
      console.log(`  Reader element: ${testId} - visible: ${isVisible}`);
    }
  });
});