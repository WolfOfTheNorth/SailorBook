import { test, expect } from '@playwright/test';

test.describe('Simple Search Test', () => {
  
  test.beforeEach(async ({ page }) => {
    // Monitor console for our debug logs
    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('🎯') || text.includes('🔍') || text.includes('🌐') || text.includes('📡') || text.includes('✅') || text.includes('❌')) {
        console.log(`🖥️  Flutter:`, text);
      }
    });
    
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(5000); // Give Flutter more time
  });

  test('Verify search integration by examining state changes', async ({ page }) => {
    console.log('🔍 Testing search integration...');
    
    // Take initial screenshot to see current state
    await page.screenshot({ path: 'test-results/app-state.png', fullPage: true });
    
    // Find the HTML structure
    const bodyContent = await page.locator('body').innerHTML();
    console.log('📄 HTML structure contains Flutter elements:', 
      bodyContent.includes('flutter-view') && bodyContent.includes('flt-glass-pane'));
    
    // Let's try to trigger search programmatically by injecting JavaScript
    console.log('💉 Attempting to trigger search programmatically...');
    
    // Try to find Flutter app instance and call search
    await page.evaluate(() => {
      console.log('🔍 Attempting to find Flutter widget tree...');
      
      // Try to access Flutter internals (this is experimental)
      const flutterView = document.querySelector('flutter-view');
      if (flutterView) {
        console.log('✅ Found flutter-view element');
      }
      
      // Log all available global objects that might be Flutter-related
      const globals = Object.getOwnPropertyNames(window);
      const flutterGlobals = globals.filter(name => 
        name.toLowerCase().includes('flutter') || 
        name.toLowerCase().includes('dart')
      );
      console.log('🌐 Flutter/Dart globals:', flutterGlobals);
    });
    
    console.log('🖱️  Trying sophisticated clicking pattern...');
    
    // Try clicking different areas methodically
    const clickAreas = [
      { name: 'top-center', x: 400, y: 100 },
      { name: 'search-tab-area', x: 300, y: 140 },
      { name: 'search-input-area', x: 300, y: 200 },
      { name: 'middle-center', x: 400, y: 300 },
    ];
    
    for (const area of clickAreas) {
      console.log(`👆 Clicking ${area.name} at (${area.x}, ${area.y})`);
      await page.click('flt-glass-pane', { position: area });
      await page.waitForTimeout(1000);
      
      // Try typing after each click
      await page.keyboard.type('test', { delay: 200 });
      await page.keyboard.press('Enter');
      await page.waitForTimeout(2000);
      
      // Clear
      await page.keyboard.press('Control+a');
      await page.keyboard.press('Delete');
      await page.waitForTimeout(500);
    }
    
    // Final attempt: simulate mobile-like touch
    console.log('📱 Trying touch simulation...');
    await page.touchscreen.tap(300, 200);
    await page.waitForTimeout(1000);
    await page.keyboard.type('alice wonderland');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: 'test-results/final-attempt.png', fullPage: true });
    
    console.log('✅ Search integration test completed - check console output above');
  });

});