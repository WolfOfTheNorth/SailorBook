import { test, expect } from '@playwright/test';

test.describe('Debug Search Functionality', () => {
  
  test.beforeEach(async ({ page }) => {
    // Listen to console logs to see our debug output
    page.on('console', msg => {
      if (msg.type() === 'log' || msg.type() === 'error') {
        console.log(`🖥️  Browser Console [${msg.type()}]:`, msg.text());
      }
    });
    
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(3000); // Allow Flutter to fully initialize
  });

  test('Debug search flow with console monitoring', async ({ page }) => {
    console.log('🔧 Starting debug search test...');
    
    // Take screenshot of initial state
    await page.screenshot({ path: 'test-results/debug-initial.png', fullPage: true });
    
    // Click search tab area
    console.log('👆 Clicking search tab area...');
    await page.click('flt-glass-pane', { position: { x: 350, y: 120 } }); // Higher up for tab bar
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/debug-search-tab.png', fullPage: true });
    
    // Try multiple search input positions
    const searchPositions = [
      { x: 300, y: 180, name: 'position1' },
      { x: 350, y: 200, name: 'position2' }, 
      { x: 200, y: 220, name: 'position3' },
    ];
    
    for (const pos of searchPositions) {
      console.log(`👆 Trying search input at ${pos.name}: (${pos.x}, ${pos.y})`);
      await page.click('flt-glass-pane', { position: pos });
      await page.waitForTimeout(1000);
      
      // Type and submit
      await page.keyboard.type('alice', { delay: 100 });
      await page.waitForTimeout(500);
      await page.keyboard.press('Enter');
      await page.waitForTimeout(3000);
      
      await page.screenshot({ path: `test-results/debug-${pos.name}.png`, fullPage: true });
      
      // Clear for next attempt
      await page.keyboard.selectAll();
      await page.keyboard.press('Delete');
      await page.waitForTimeout(500);
    }
    
    console.log('✅ Debug test completed - check console logs above');
  });

  test('Try with finer control', async ({ page }) => {
    console.log('🎯 Trying with more precise targeting...');
    
    // Wait a bit more for Flutter
    await page.waitForTimeout(5000);
    
    // Try to find any input-like elements
    console.log('🔍 Looking for input elements...');
    const inputs = await page.locator('input').count();
    console.log(`Found ${inputs} input elements`);
    
    if (inputs > 0) {
      console.log('📝 Found input element, trying to use it...');
      await page.locator('input').first().fill('alice wonderland');
      await page.keyboard.press('Enter');
      await page.waitForTimeout(3000);
    }
    
    // Also try textarea
    const textareas = await page.locator('textarea').count();
    console.log(`Found ${textareas} textarea elements`);
    
    if (textareas > 0) {
      console.log('📝 Found textarea element, trying to use it...');
      await page.locator('textarea').first().fill('alice wonderland');
      await page.keyboard.press('Enter');
      await page.waitForTimeout(3000);
    }
    
    await page.screenshot({ path: 'test-results/debug-element-targeting.png', fullPage: true });
    
    console.log('✅ Element targeting test completed');
  });

});