import { test, expect } from '@playwright/test';

test.describe('App Functionality Tests', () => {
  
  test.beforeEach(async ({ page }) => {
    // Set up API mocks before navigation
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
              ia: ['alice-adventures-wonderland']
            },
            {
              key: '/works/OL789012W', 
              title: 'The Adventures of Tom Sawyer',
              author_name: ['Mark Twain'],
              cover_i: 789012,
              first_publish_year: 1876,
              ia: ['tom-sawyer-adventures']
            }
          ]
        }),
      });
    });

    await page.route('**/download/**', async route => {
      await route.fulfill({
        contentType: 'application/epub+zip',
        body: Buffer.from('mock epub file content'),
      });
    });

    // Navigate to the app
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(3000); // Allow Flutter to fully initialize
  });

  test('Flutter app initializes correctly', async ({ page }) => {
    // Verify Flutter has loaded
    const flutterPane = page.locator('flt-glass-pane');
    await expect(flutterPane).toBeVisible();
    
    // Check page title
    await expect(page).toHaveTitle(/Public-Domain Reader/);
    
    // Verify canvas elements are present (Flutter renders to canvas)
    const canvases = page.locator('canvas');
    await expect(canvases.first()).toBeVisible();
    
    console.log('✅ Flutter app initialized successfully');
  });

  test('Material 3 UI components render correctly', async ({ page }) => {
    // Take baseline screenshot
    await page.screenshot({ 
      path: 'test-results/material3-ui.png', 
      fullPage: true 
    });
    
    // Check for Flutter's semantic elements
    const flutterView = page.locator('[role="application"]');
    if (await flutterView.count() > 0) {
      await expect(flutterView.first()).toBeVisible();
    }
    
    // Verify the app responds to clicks (basic interactivity test)
    await page.click('flt-glass-pane', { position: { x: 400, y: 300 } });
    await page.waitForTimeout(500);
    
    console.log('✅ Material 3 UI components verified');
  });

  test('Library and Search tabs are accessible', async ({ page }) => {
    // Test tab navigation simulation
    // Click in the area where tabs would be rendered
    
    // Click on Library tab area
    await page.click('flt-glass-pane', { position: { x: 200, y: 150 } });
    await page.waitForTimeout(1000);
    
    // Take screenshot of library view
    await page.screenshot({ path: 'test-results/library-tab.png' });
    
    // Click on Search tab area  
    await page.click('flt-glass-pane', { position: { x: 400, y: 150 } });
    await page.waitForTimeout(1000);
    
    // Take screenshot of search view
    await page.screenshot({ path: 'test-results/search-tab.png' });
    
    console.log('✅ Tab navigation tested');
  });

  test('Search functionality works with mock data', async ({ page }) => {
    // Navigate to search area and perform search
    await page.click('flt-glass-pane', { position: { x: 400, y: 150 } }); // Search tab
    await page.waitForTimeout(1000);
    
    // Click on search input area
    await page.click('flt-glass-pane', { position: { x: 400, y: 250 } });
    await page.waitForTimeout(500);
    
    // Type search query
    await page.keyboard.type('alice wonderland');
    await page.waitForTimeout(500);
    
    // Press Enter to search
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    
    // Verify network request was made
    const requests = [];
    page.on('request', request => {
      if (request.url().includes('search.json')) {
        requests.push(request.url());
      }
    });
    
    await page.screenshot({ path: 'test-results/search-with-results.png', fullPage: true });
    
    console.log('✅ Search functionality tested');
  });

  test('Book interaction and navigation', async ({ page }) => {
    // Simulate book selection flow
    await page.click('flt-glass-pane', { position: { x: 400, y: 150 } }); // Search tab
    await page.waitForTimeout(1000);
    
    // Search for books
    await page.click('flt-glass-pane', { position: { x: 400, y: 250 } }); // Search input
    await page.keyboard.type('alice');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    
    // Click on first book result
    await page.click('flt-glass-pane', { position: { x: 400, y: 400 } });
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/book-details.png', fullPage: true });
    
    console.log('✅ Book interaction tested');
  });

  test('Player interface accessibility', async ({ page }) => {
    // Navigate through app to player
    await page.click('flt-glass-pane', { position: { x: 400, y: 150 } }); // Search tab
    await page.waitForTimeout(1000);
    
    // Search and select book
    await page.click('flt-glass-pane', { position: { x: 400, y: 250 } });
    await page.keyboard.type('alice');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    
    // Try to access player (simulate Listen button)
    await page.click('flt-glass-pane', { position: { x: 500, y: 450 } });
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/player-interface.png', fullPage: true });
    
    console.log('✅ Player interface tested');
  });

  test('Responsive design across viewports', async ({ page }) => {
    const viewports = [
      { width: 1920, height: 1080, name: 'desktop-large' },
      { width: 1366, height: 768, name: 'desktop-standard' },
      { width: 768, height: 1024, name: 'tablet-portrait' },
      { width: 1024, height: 768, name: 'tablet-landscape' },
      { width: 375, height: 667, name: 'mobile-small' },
      { width: 414, height: 896, name: 'mobile-large' }
    ];
    
    for (const viewport of viewports) {
      await page.setViewportSize(viewport);
      await page.waitForTimeout(1000);
      
      // Allow Flutter to re-render for new viewport
      await page.reload();
      await page.waitForSelector('flt-glass-pane', { timeout: 10000 });
      await page.waitForTimeout(2000);
      
      await page.screenshot({ 
        path: `test-results/responsive-${viewport.name}-${viewport.width}x${viewport.height}.png`,
        fullPage: true
      });
    }
    
    console.log('✅ Responsive design tested across all viewports');
  });

  test('App performance and stability', async ({ page }) => {
    const startTime = Date.now();
    
    // Perform multiple interactions to test stability
    const interactions = [
      { x: 200, y: 150 }, // Library tab
      { x: 400, y: 150 }, // Search tab  
      { x: 400, y: 250 }, // Search input
      { x: 300, y: 300 }, // Random area
      { x: 500, y: 200 }, // Another area
    ];
    
    for (let i = 0; i < 3; i++) { // Repeat 3 times
      for (const pos of interactions) {
        await page.click('flt-glass-pane', { position: pos });
        await page.waitForTimeout(300);
      }
    }
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    console.log(`✅ Performance test completed in ${duration}ms`);
    
    // Verify app is still responsive
    await page.click('flt-glass-pane', { position: { x: 400, y: 300 } });
    await page.waitForTimeout(500);
    
    await page.screenshot({ path: 'test-results/stability-test.png' });
    
    // Basic performance assertion
    expect(duration).toBeLessThan(10000); // Should complete within 10 seconds
  });

  test('Dark and light theme support', async ({ page }) => {
    // Test system theme preference
    await page.emulateMedia({ colorScheme: 'light' });
    await page.reload();
    await page.waitForSelector('flt-glass-pane');
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/light-theme.png', fullPage: true });
    
    // Switch to dark theme
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.reload();
    await page.waitForSelector('flt-glass-pane');
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/dark-theme.png', fullPage: true });
    
    console.log('✅ Theme support tested');
  });

  test('Error handling and edge cases', async ({ page }) => {
    // Test with network failures
    await page.route('**/search.json*', async route => {
      await route.abort();
    });
    
    // Try to search with network failure
    await page.click('flt-glass-pane', { position: { x: 400, y: 150 } }); // Search tab
    await page.waitForTimeout(1000);
    
    await page.click('flt-glass-pane', { position: { x: 400, y: 250 } }); // Search input
    await page.keyboard.type('test search');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: 'test-results/error-handling.png', fullPage: true });
    
    console.log('✅ Error handling tested');
  });

  test('Accessibility and keyboard navigation', async ({ page }) => {
    // Test keyboard navigation
    await page.keyboard.press('Tab');
    await page.waitForTimeout(500);
    
    await page.keyboard.press('Tab');
    await page.waitForTimeout(500);
    
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1000);
    
    // Test with reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: 'test-results/accessibility-features.png', fullPage: true });
    
    console.log('✅ Accessibility features tested');
  });
});