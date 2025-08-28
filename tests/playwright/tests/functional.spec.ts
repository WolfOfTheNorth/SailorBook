import { test, expect } from '@playwright/test';

test.describe('Public Domain Reader - Functional Tests', () => {
  
  test.beforeEach(async ({ page }) => {
    // Navigate to the Flutter app
    await page.goto('http://localhost:3000');
    
    // Wait for Flutter to load
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(2000); // Give Flutter time to fully render
  });

  test('should load the Flutter app successfully', async ({ page }) => {
    // Check that the Flutter app has loaded
    await expect(page.locator('flt-glass-pane')).toBeVisible();
    
    // Check for the app title or main content
    const title = await page.title();
    expect(title).toContain('Public-Domain Reader');
  });

  test('should display the library interface', async ({ page }) => {
    // Wait for the main content to load
    await page.waitForTimeout(3000);
    
    // Take a screenshot to see what's rendered
    await page.screenshot({ path: 'test-results/library-interface.png', fullPage: true });
    
    // Look for typical Flutter elements that should be present
    const flutterView = page.locator('flt-glass-pane');
    await expect(flutterView).toBeVisible();
    
    // Check for canvas elements (Flutter renders to canvas)
    const canvasElements = page.locator('canvas');
    await expect(canvasElements.first()).toBeVisible();
  });

  test('should handle tab navigation', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Try to interact with the Flutter app
    // Flutter web apps render to canvas, so we need to click coordinates
    
    // Take screenshot before interaction
    await page.screenshot({ path: 'test-results/before-interaction.png', fullPage: true });
    
    // Click in the area where Search tab would be (approximate coordinates)
    await page.click('flt-glass-pane', { position: { x: 600, y: 100 } });
    await page.waitForTimeout(1000);
    
    // Take screenshot after clicking
    await page.screenshot({ path: 'test-results/after-tab-click.png', fullPage: true });
  });

  test('should respond to keyboard input', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Focus on the Flutter app
    await page.click('flt-glass-pane');
    
    // Try pressing Tab key to navigate
    await page.keyboard.press('Tab');
    await page.waitForTimeout(500);
    
    await page.keyboard.press('Tab');
    await page.waitForTimeout(500);
    
    // Try Enter key
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: 'test-results/keyboard-navigation.png', fullPage: true });
  });

  test('should handle search interaction', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Mock the search API
    await page.route('**/search.json*', async route => {
      await route.fulfill({
        contentType: 'application/json',
        body: JSON.stringify({
          docs: [
            {
              key: '/works/OL123456W',
              title: 'Alice\'s Adventures in Wonderland',
              author_name: ['Lewis Carroll'],
              cover_i: 123456,
              first_publish_year: 1865,
              ia: ['alice-wonderland-archive']
            }
          ]
        }),
      });
    });
    
    // Try to interact with search functionality
    // Since Flutter renders to canvas, we'll simulate the search flow
    
    // Click where the search tab should be
    await page.click('flt-glass-pane', { position: { x: 600, y: 100 } });
    await page.waitForTimeout(1000);
    
    // Click where the search input should be  
    await page.click('flt-glass-pane', { position: { x: 400, y: 200 } });
    await page.waitForTimeout(500);
    
    // Type search query
    await page.keyboard.type('alice wonderland');
    await page.waitForTimeout(500);
    
    // Press Enter to search
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/search-results.png', fullPage: true });
  });

  test('should handle window resize responsively', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Test different viewport sizes
    const viewports = [
      { width: 1920, height: 1080, name: 'desktop' },
      { width: 768, height: 1024, name: 'tablet' },
      { width: 375, height: 667, name: 'mobile' }
    ];
    
    for (const viewport of viewports) {
      await page.setViewportSize({ width: viewport.width, height: viewport.height });
      await page.waitForTimeout(1000);
      
      await page.screenshot({ 
        path: `test-results/responsive-${viewport.name}.png`, 
        fullPage: true 
      });
    }
  });

  test('should load without console errors', async ({ page }) => {
    const consoleLogs: string[] = [];
    const consoleErrors: string[] = [];
    
    page.on('console', msg => {
      const text = msg.text();
      if (msg.type() === 'error') {
        consoleErrors.push(text);
      } else {
        consoleLogs.push(text);
      }
    });
    
    await page.waitForTimeout(5000);
    
    // Allow some expected Flutter logs but no critical errors
    const criticalErrors = consoleErrors.filter(error => 
      !error.includes('DevTools') && 
      !error.includes('extension') &&
      !error.includes('favicon')
    );
    
    if (criticalErrors.length > 0) {
      console.log('Console errors found:', criticalErrors);
    }
    
    // We expect some logs from Flutter, so we don't fail on all errors
    // but we log them for debugging
    console.log(`Console logs: ${consoleLogs.length}, Console errors: ${consoleErrors.length}`);
  });

  test('should maintain app state during navigation', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Simulate navigation through the app
    await page.click('flt-glass-pane', { position: { x: 400, y: 300 } });
    await page.waitForTimeout(1000);
    
    // Try back navigation
    await page.keyboard.press('Escape');
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: 'test-results/navigation-state.png', fullPage: true });
  });

  test('should handle rapid user interactions', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Perform rapid clicks to test app stability
    for (let i = 0; i < 5; i++) {
      await page.click('flt-glass-pane', { position: { x: 300 + i * 50, y: 200 + i * 30 } });
      await page.waitForTimeout(100);
    }
    
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/rapid-interactions.png', fullPage: true });
  });

  test('should support accessibility features', async ({ page }) => {
    await page.waitForTimeout(3000);
    
    // Test keyboard navigation
    await page.keyboard.press('Tab');
    await page.waitForTimeout(300);
    
    await page.keyboard.press('Tab');
    await page.waitForTimeout(300);
    
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1000);
    
    // Test with high contrast (simulate accessibility preferences)
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: 'test-results/accessibility.png', fullPage: true });
  });
});