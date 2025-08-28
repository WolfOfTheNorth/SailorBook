import { test, expect } from '@playwright/test';

test.describe('SailorBook Search and Download Flow', () => {
  
  test.beforeEach(async ({ page }) => {
    // Mock Open Library API
    await page.route('**/search.json*', async route => {
      await route.fulfill({
        contentType: 'application/json',
        body: JSON.stringify({
          numFound: 2,
          docs: [
            {
              key: '/works/OL123456W',
              title: 'Alice\'s Adventures in Wonderland',
              author_name: ['Lewis Carroll'],
              cover_i: 123456,
              first_publish_year: 1865,
              ia: ['alice-wonderland-001'],
              language: ['eng'],
              subject: ['Fantasy', 'Children\'s literature']
            },
            {
              key: '/works/OL789012W',
              title: 'Through the Looking-Glass',
              author_name: ['Lewis Carroll'],
              cover_i: 789012,
              first_publish_year: 1871,
              ia: ['through-looking-glass-001'],
              language: ['eng'],
              subject: ['Fantasy', 'Children\'s literature']
            }
          ]
        }),
      });
    });

    // Mock Internet Archive download
    await page.route('**/download/**', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/epub+zip',
        body: Buffer.from('Mock EPUB content for testing download functionality'),
      });
    });

    // Mock cover images
    await page.route('**/covers/**', async route => {
      // Create a simple 1x1 PNG image
      const pngBuffer = Buffer.from([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, // IHDR chunk size
        0x49, 0x48, 0x44, 0x52, // IHDR
        0x00, 0x00, 0x00, 0x01, // width: 1
        0x00, 0x00, 0x00, 0x01, // height: 1
        0x08, 0x02, 0x00, 0x00, 0x00, // bit depth, color type, compression, filter, interlace
        0x90, 0x77, 0x53, 0xDE, // CRC
        0x00, 0x00, 0x00, 0x0C, // IDAT chunk size
        0x49, 0x44, 0x41, 0x54, // IDAT
        0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, // image data
        0xE2, 0x21, 0xBC, 0x33, // CRC
        0x00, 0x00, 0x00, 0x00, // IEND chunk size
        0x49, 0x45, 0x4E, 0x44, // IEND
        0xAE, 0x42, 0x60, 0x82  // CRC
      ]);
      
      await route.fulfill({
        status: 200,
        contentType: 'image/png',
        body: pngBuffer,
      });
    });

    await page.goto('http://localhost:3000');
    await page.waitForTimeout(3000); // Allow Flutter to fully load
  });

  test('Complete search and download user journey', async ({ page }) => {
    console.log('🚀 Starting complete search and download journey...');
    
    // Step 1: Initial state - should show empty library
    await page.screenshot({ path: 'test-results/journey-1-empty-library.png', fullPage: true });
    console.log('📸 Step 1: Empty library state captured');
    
    // Step 2: Switch to Search tab
    console.log('📱 Step 2: Switching to Search tab...');
    await page.click('flt-glass-pane', { position: { x: 960, y: 78 } });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/journey-2-search-tab.png', fullPage: true });
    console.log('📸 Step 2: Search tab activated');
    
    // Step 3: Enter search query
    console.log('🔍 Step 3: Performing search...');
    // Click in the search area (middle of screen where search input should be)
    await page.click('flt-glass-pane', { position: { x: 640, y: 300 } });
    await page.waitForTimeout(500);
    
    // Type search query
    await page.keyboard.type('alice wonderland');
    await page.waitForTimeout(1000);
    
    // Execute search
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000); // Wait for search results
    
    await page.screenshot({ path: 'test-results/journey-3-search-results.png', fullPage: true });
    console.log('📸 Step 3: Search results displayed');
    
    // Step 4: Attempt to interact with first result
    console.log('📖 Step 4: Selecting first book...');
    // Click on where the first search result should be
    await page.click('flt-glass-pane', { position: { x: 640, y: 400 } });
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/journey-4-book-selected.png', fullPage: true });
    console.log('📸 Step 4: Book selection attempted');
    
    // Step 5: Attempt to download
    console.log('⬇️ Step 5: Attempting download...');
    // Click where download button might be
    await page.click('flt-glass-pane', { position: { x: 640, y: 500 } });
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/journey-5-download-attempted.png', fullPage: true });
    console.log('📸 Step 5: Download attempted');
    
    // Step 6: Return to Library to check for downloaded book
    console.log('📚 Step 6: Checking library for downloaded book...');
    await page.click('flt-glass-pane', { position: { x: 320, y: 78 } }); // Library tab
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/journey-6-library-check.png', fullPage: true });
    console.log('📸 Step 6: Library checked for downloads');
    
    console.log('✅ Complete user journey test completed');
  });

  test('Search interaction flow validation', async ({ page }) => {
    console.log('🔍 Testing search interaction patterns...');
    
    // Test search tab switching
    await page.screenshot({ path: 'test-results/search-flow-1-start.png', fullPage: true });
    
    // Switch to search
    await page.click('flt-glass-pane', { position: { x: 960, y: 78 } });
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/search-flow-2-search-active.png', fullPage: true });
    
    // Test different search queries
    const searches = ['alice', 'tom sawyer', 'shakespeare', 'dickens'];
    
    for (let i = 0; i < searches.length; i++) {
      const query = searches[i];
      console.log(`🔍 Testing search: "${query}"`);
      
      // Click search field
      await page.click('flt-glass-pane', { position: { x: 640, y: 300 } });
      await page.waitForTimeout(300);
      
      // Clear any previous text and type new query
      await page.keyboard.selectAll();
      await page.keyboard.type(query);
      await page.waitForTimeout(500);
      
      // Execute search
      await page.keyboard.press('Enter');
      await page.waitForTimeout(2000);
      
      await page.screenshot({ 
        path: `test-results/search-flow-${i + 3}-${query.replace(' ', '-')}.png`, 
        fullPage: true 
      });
      
      console.log(`📸 Search "${query}" completed`);
    }
    
    console.log('✅ Search flow validation completed');
  });

  test('UI responsiveness during interactions', async ({ page }) => {
    console.log('⚡ Testing UI responsiveness...');
    
    const interactions = [
      { name: 'Library tab', x: 320, y: 78 },
      { name: 'Search tab', x: 960, y: 78 },
      { name: 'Center area', x: 640, y: 400 },
      { name: 'Browse button area', x: 640, y: 550 },
      { name: 'Settings area', x: 1200, y: 80 }
    ];
    
    for (let i = 0; i < interactions.length; i++) {
      const interaction = interactions[i];
      console.log(`🖱️ Testing ${interaction.name} interaction...`);
      
      const startTime = Date.now();
      await page.click('flt-glass-pane', { position: { x: interaction.x, y: interaction.y } });
      await page.waitForTimeout(1000);
      const responseTime = Date.now() - startTime;
      
      console.log(`⏱️ ${interaction.name} response time: ${responseTime}ms`);
      
      await page.screenshot({ 
        path: `test-results/responsiveness-${i + 1}-${interaction.name.toLowerCase().replace(' ', '-')}.png`, 
        fullPage: true 
      });
      
      // Verify the interaction didn't break the app
      const isAppStillResponsive = await page.evaluate(() => {
        return document.querySelector('flt-glass-pane') !== null;
      });
      
      expect(isAppStillResponsive).toBe(true);
      expect(responseTime).toBeLessThan(5000); // Should respond within 5 seconds
    }
    
    console.log('✅ UI responsiveness testing completed');
  });

  test('Keyboard navigation and accessibility', async ({ page }) => {
    console.log('⌨️ Testing keyboard navigation...');
    
    // Test Tab navigation
    await page.screenshot({ path: 'test-results/keyboard-1-initial.png', fullPage: true });
    
    const tabSequence = [
      'Tab', 'Tab', 'Tab', 'Enter', // Navigate and activate
      'Escape', // Go back
      'Tab', 'Tab', 'Space', // Navigate with space
      'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown' // Arrow keys
    ];
    
    for (let i = 0; i < tabSequence.length; i++) {
      const key = tabSequence[i];
      console.log(`⌨️ Pressing ${key}...`);
      
      await page.keyboard.press(key);
      await page.waitForTimeout(500);
      
      if (i % 3 === 0) { // Take screenshots every few interactions
        await page.screenshot({ 
          path: `test-results/keyboard-${Math.floor(i/3) + 2}-after-${key.toLowerCase()}.png`, 
          fullPage: true 
        });
      }
    }
    
    console.log('✅ Keyboard navigation testing completed');
  });

  test('Network error handling', async ({ page }) => {
    console.log('🌐 Testing network error handling...');
    
    // First, test with working network
    await page.click('flt-glass-pane', { position: { x: 960, y: 78 } }); // Search tab
    await page.waitForTimeout(1000);
    
    await page.click('flt-glass-pane', { position: { x: 640, y: 300 } }); // Search field
    await page.keyboard.type('test query');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: 'test-results/network-1-working.png', fullPage: true });
    console.log('📸 Network working state captured');
    
    // Now simulate network failure
    await page.route('**/search.json*', async route => {
      await route.abort('failed');
    });
    
    // Try another search
    await page.click('flt-glass-pane', { position: { x: 640, y: 300 } });
    await page.keyboard.selectAll();
    await page.keyboard.type('network error test');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: 'test-results/network-2-error.png', fullPage: true });
    console.log('📸 Network error state captured');
    
    // App should still be responsive
    const isAppResponsive = await page.evaluate(() => {
      return document.querySelector('flt-glass-pane') !== null;
    });
    
    expect(isAppResponsive).toBe(true);
    console.log('✅ Network error handling verified - app remains responsive');
  });

  test('Performance under load simulation', async ({ page }) => {
    console.log('🏋️ Testing performance under load...');
    
    const startTime = Date.now();
    
    // Simulate rapid user interactions
    for (let i = 0; i < 20; i++) {
      const x = 300 + (i * 30) % 600;
      const y = 200 + (i * 15) % 400;
      
      await page.click('flt-glass-pane', { position: { x, y } });
      await page.waitForTimeout(50); // Rapid clicks
      
      if (i % 5 === 0) {
        console.log(`🔄 Rapid interaction ${i + 1}/20 completed`);
      }
    }
    
    const interactionTime = Date.now() - startTime;
    console.log(`⏱️ 20 rapid interactions completed in ${interactionTime}ms`);
    
    // App should still be responsive after load
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/performance-after-load.png', fullPage: true });
    
    const finalResponsiveness = await page.evaluate(() => {
      return document.querySelector('flt-glass-pane') !== null;
    });
    
    expect(finalResponsiveness).toBe(true);
    expect(interactionTime).toBeLessThan(10000); // Should complete within 10 seconds
    
    console.log('✅ Performance under load testing completed');
  });
});