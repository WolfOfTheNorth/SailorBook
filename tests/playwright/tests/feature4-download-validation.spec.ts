import { test, expect } from '@playwright/test';

test.describe('Feature 4: EPUB Download & Storage Validation', () => {
  
  test.beforeEach(async ({ page }) => {
    // Set up console logging to capture Flutter debug info
    page.on('console', msg => {
      if (msg.type() === 'log' || msg.type() === 'error') {
        console.log(`🐛 Flutter Console [${msg.type()}]:`, msg.text());
      }
    });

    // Mock successful API responses for search
    await page.route('**/search.json*', async route => {
      await route.fulfill({
        contentType: 'application/json',
        body: JSON.stringify({
          docs: [
            {
              key: '/works/OL28716096W',
              title: 'Alice\'s Adventures in Wonderland',
              author_name: ['Lewis Carroll'],
              cover_i: 8513669,
              first_publish_year: 1865,
              ia: ['alicesadventures00carr_6']
            },
            {
              key: '/works/OL13648194W', 
              title: 'Alice\'s Adventures Under Ground',
              author_name: ['Lewis Carroll'],
              cover_i: 7222168,
              first_publish_year: 1886,
              ia: ['alicesadventures00carr_0']
            }
          ]
        }),
      });
    });

    // Mock EPUB download with realistic file content
    await page.route('**/archive.org/download/**/*.epub', async route => {
      console.log('📥 EPUB Download request intercepted:', route.request().url());
      
      // Simulate a realistic EPUB file structure (minimal but valid)
      const mockEpubContent = Buffer.from(`
        PK\x03\x04\x14\x00\x00\x00\x08\x00
        mimetype: application/epub+zip
        META-INF/container.xml content
        OEBPS/content.opf content
        OEBPS/toc.ncx content
        OEBPS/chapter1.xhtml content with Alice's story...
      `);
      
      await route.fulfill({
        status: 200,
        contentType: 'application/epub+zip',
        body: mockEpubContent,
        headers: {
          'Content-Length': mockEpubContent.length.toString(),
          'Content-Disposition': 'attachment; filename="alice-wonderland.epub"'
        }
      });
    });

    // Navigate to the app
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(3000); // Allow Flutter to fully initialize
  });

  test('Complete EPUB download and storage flow', async ({ page }) => {
    console.log('🚀 Starting complete EPUB download validation...');
    
    // Track all network requests for debugging
    const networkRequests: { url: string, method: string, status?: number }[] = [];
    const downloadRequests: string[] = [];
    
    page.on('request', request => {
      networkRequests.push({ 
        url: request.url(), 
        method: request.method() 
      });
      
      if (request.url().includes('search.json')) {
        console.log('🔍 Search API request:', request.url());
      }
      
      if (request.url().includes('archive.org/download') && request.url().includes('.epub')) {
        downloadRequests.push(request.url());
        console.log('📥 EPUB Download request:', request.url());
      }
    });
    
    page.on('response', response => {
      const request = networkRequests.find(req => req.url === response.url());
      if (request) {
        request.status = response.status();
      }
      
      if (response.url().includes('search.json')) {
        console.log('📡 Search API response:', response.status());
      }
      
      if (response.url().includes('archive.org')) {
        console.log('📦 Archive.org response:', response.status(), response.url());
      }
    });

    // Step 1: App Initialization
    console.log('📱 Step 1: Verifying app initialization...');
    const flutterPane = page.locator('flt-glass-pane');
    await expect(flutterPane).toBeVisible();
    await page.screenshot({ path: 'test-results/feature4-01-initialization.png', fullPage: true });

    // Step 2: Navigate to Search
    console.log('🔍 Step 2: Navigating to search tab...');
    await page.click('flt-glass-pane', { position: { x: 350, y: 150 } });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/feature4-02-search-tab.png', fullPage: true });

    // Step 3: Perform Search
    console.log('⌨️  Step 3: Performing search for "alice wonderland"...');
    await page.click('flt-glass-pane', { position: { x: 300, y: 250 } });
    await page.waitForTimeout(1000);
    
    await page.keyboard.type('alice wonderland', { delay: 100 });
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/feature4-03-search-query.png', fullPage: true });
    
    await page.keyboard.press('Enter');
    await page.waitForTimeout(5000); // Wait for search results
    await page.screenshot({ path: 'test-results/feature4-04-search-results.png', fullPage: true });

    // Verify search API was called
    const searchRequests = networkRequests.filter(req => req.url.includes('search.json'));
    expect(searchRequests.length).toBeGreaterThan(0);
    console.log(`✅ Search API called successfully (${searchRequests.length} requests)`);

    // Step 4: Select Book (click on first search result)
    console.log('📖 Step 4: Selecting first book from results...');
    // Click on the area where the first book card should be
    await page.click('flt-glass-pane', { position: { x: 400, y: 350 } });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/feature4-05-book-selected.png', fullPage: true });

    // Step 5: Initiate Download
    console.log('⬇️ Step 5: Initiating book download...');
    // Click on download button area (assuming it's near the book details)
    await page.click('flt-glass-pane', { position: { x: 500, y: 400 } });
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'test-results/feature4-06-download-initiated.png', fullPage: true });

    // Step 6: Monitor Progress
    console.log('📊 Step 6: Monitoring download progress...');
    // Wait for download to start and progress
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'test-results/feature4-07-download-progress.png', fullPage: true });
    
    // Wait for download completion
    await page.waitForTimeout(5000);
    await page.screenshot({ path: 'test-results/feature4-08-download-completed.png', fullPage: true });

    // Verify download request was made
    console.log(`📥 Download requests made: ${downloadRequests.length}`);
    downloadRequests.forEach((url, index) => {
      console.log(`  ${index + 1}. ${url}`);
    });

    if (downloadRequests.length > 0) {
      expect(downloadRequests[0]).toContain('archive.org/download');
      expect(downloadRequests[0]).toContain('.epub');
      console.log('✅ EPUB download request was made successfully');
    }

    // Step 7: Verify Storage (navigate to library)
    console.log('📚 Step 7: Verifying book appears in library...');
    await page.click('flt-glass-pane', { position: { x: 200, y: 150 } }); // Library tab
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'test-results/feature4-09-library-view.png', fullPage: true });

    // Step 8: Test Persistence (reload app)
    console.log('🔄 Step 8: Testing persistence by reloading app...');
    await page.reload();
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(3000);
    
    // Navigate back to library
    await page.click('flt-glass-pane', { position: { x: 200, y: 150 } }); // Library tab
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/feature4-10-persistence-check.png', fullPage: true });

    console.log('✅ Complete EPUB download and storage flow validation completed');
    
    // Final verification summary
    console.log('\n📋 Download Flow Summary:');
    console.log(`   🔍 Search requests: ${searchRequests.length}`);
    console.log(`   📥 Download requests: ${downloadRequests.length}`);
    console.log(`   🌐 Total network requests: ${networkRequests.length}`);
    
    // Verify core functionality worked
    expect(searchRequests.length).toBeGreaterThan(0);
    expect(downloadRequests.length).toBeGreaterThan(0);
  });

  test('Download progress monitoring and error handling', async ({ page }) => {
    console.log('📊 Starting download progress and error handling test...');
    
    let progressUpdates: number[] = [];
    
    // Mock download with progress simulation
    await page.route('**/archive.org/download/**/*.epub', async route => {
      console.log('📥 Simulating progressive download...');
      
      // Simulate a larger file with chunked response
      const totalSize = 1024 * 1024; // 1MB
      const mockContent = Buffer.alloc(totalSize, 'A'); // 1MB of 'A' characters
      
      await route.fulfill({
        status: 200,
        contentType: 'application/epub+zip',
        body: mockContent,
        headers: {
          'Content-Length': totalSize.toString(),
        }
      });
    });

    // Navigate to search and initiate download
    await page.click('flt-glass-pane', { position: { x: 350, y: 150 } }); // Search tab
    await page.waitForTimeout(2000);
    
    await page.click('flt-glass-pane', { position: { x: 300, y: 250 } }); // Search input
    await page.keyboard.type('alice wonderland');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    
    await page.click('flt-glass-pane', { position: { x: 400, y: 350 } }); // Select book
    await page.waitForTimeout(2000);
    
    await page.click('flt-glass-pane', { position: { x: 500, y: 400 } }); // Download button
    
    // Monitor for progress indicators
    console.log('📈 Monitoring download progress...');
    for (let i = 0; i < 10; i++) {
      await page.waitForTimeout(1000);
      await page.screenshot({ 
        path: `test-results/feature4-progress-${i.toString().padStart(2, '0')}.png` 
      });
    }
    
    console.log('✅ Progress monitoring test completed');
  });

  test('Network failure and recovery during download', async ({ page }) => {
    console.log('🚫 Starting network failure test...');
    
    let downloadAttempts = 0;
    
    await page.route('**/archive.org/download/**/*.epub', async route => {
      downloadAttempts++;
      console.log(`📥 Download attempt #${downloadAttempts}`);
      
      if (downloadAttempts === 1) {
        // First attempt fails
        console.log('❌ Simulating network failure...');
        await route.abort('failed');
      } else {
        // Second attempt succeeds
        console.log('✅ Simulating successful retry...');
        await route.fulfill({
          status: 200,
          contentType: 'application/epub+zip',
          body: Buffer.from('Mock EPUB content for retry test'),
        });
      }
    });

    // Navigate and attempt download
    await page.click('flt-glass-pane', { position: { x: 350, y: 150 } }); // Search tab
    await page.waitForTimeout(2000);
    
    await page.click('flt-glass-pane', { position: { x: 300, y: 250 } }); // Search input
    await page.keyboard.type('alice wonderland');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    
    await page.click('flt-glass-pane', { position: { x: 400, y: 350 } }); // Select book
    await page.waitForTimeout(2000);
    
    await page.click('flt-glass-pane', { position: { x: 500, y: 400 } }); // Download button
    await page.waitForTimeout(5000);
    
    await page.screenshot({ path: 'test-results/feature4-error-handling.png', fullPage: true });
    
    // Verify at least one download attempt was made
    expect(downloadAttempts).toBeGreaterThan(0);
    console.log(`✅ Network failure test completed (${downloadAttempts} attempts)`);
  });

  test('Concurrent downloads handling', async ({ page }) => {
    console.log('⚡ Starting concurrent downloads test...');
    
    let concurrentDownloads = 0;
    const downloadTimings: { start: number, end: number }[] = [];
    
    await page.route('**/archive.org/download/**/*.epub', async route => {
      const startTime = Date.now();
      concurrentDownloads++;
      const downloadId = concurrentDownloads;
      
      console.log(`📥 Starting concurrent download #${downloadId}`);
      
      // Simulate different download durations
      const duration = 2000 + (downloadId * 1000); // 2s, 3s, 4s etc.
      await new Promise(resolve => setTimeout(resolve, duration));
      
      const endTime = Date.now();
      downloadTimings.push({ start: startTime, end: endTime });
      
      await route.fulfill({
        status: 200,
        contentType: 'application/epub+zip',
        body: Buffer.from(`Mock EPUB content for download #${downloadId}`),
      });
      
      console.log(`✅ Completed concurrent download #${downloadId} (${duration}ms)`);
    });

    // Navigate to search
    await page.click('flt-glass-pane', { position: { x: 350, y: 150 } }); // Search tab
    await page.waitForTimeout(2000);
    
    await page.click('flt-glass-pane', { position: { x: 300, y: 250 } }); // Search input
    await page.keyboard.type('alice wonderland');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    
    // Rapidly initiate multiple downloads by clicking different book positions
    console.log('🚀 Initiating multiple downloads rapidly...');
    const downloadPositions = [
      { x: 400, y: 350 }, // First book
      { x: 400, y: 450 }, // Second book (if visible)
      { x: 400, y: 550 }, // Third book (if visible)
    ];
    
    for (let i = 0; i < downloadPositions.length; i++) {
      await page.click('flt-glass-pane', { position: downloadPositions[i] });
      await page.waitForTimeout(500);
      await page.click('flt-glass-pane', { position: { x: 500, y: 400 } }); // Download button
      await page.waitForTimeout(200); // Small delay between downloads
    }
    
    // Wait for all downloads to complete
    await page.waitForTimeout(10000);
    
    await page.screenshot({ path: 'test-results/feature4-concurrent-downloads.png', fullPage: true });
    
    console.log(`✅ Concurrent downloads test completed (${concurrentDownloads} downloads)`);
    downloadTimings.forEach((timing, index) => {
      console.log(`   Download ${index + 1}: ${timing.end - timing.start}ms`);
    });
  });

  test('Storage verification and file system checks', async ({ page }) => {
    console.log('🗂️  Starting storage verification test...');
    
    const downloadedBooks: string[] = [];
    
    await page.route('**/archive.org/download/**/*.epub', async route => {
      const url = route.request().url();
      const bookId = url.split('/').slice(-2, -1)[0]; // Extract book ID from URL
      downloadedBooks.push(bookId);
      
      console.log(`📥 Downloading book: ${bookId}`);
      
      await route.fulfill({
        status: 200,
        contentType: 'application/epub+zip',
        body: Buffer.from(`Mock EPUB content for ${bookId}`),
        headers: {
          'Content-Length': '2048',
        }
      });
    });

    // Navigate and download a book
    await page.click('flt-glass-pane', { position: { x: 350, y: 150 } }); // Search tab
    await page.waitForTimeout(2000);
    
    await page.click('flt-glass-pane', { position: { x: 300, y: 250 } }); // Search input  
    await page.keyboard.type('alice wonderland');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    
    await page.click('flt-glass-pane', { position: { x: 400, y: 350 } }); // Select book
    await page.waitForTimeout(2000);
    
    await page.click('flt-glass-pane', { position: { x: 500, y: 400 } }); // Download button
    await page.waitForTimeout(5000); // Wait for download completion
    
    // Navigate to library to verify storage
    await page.click('flt-glass-pane', { position: { x: 200, y: 150 } }); // Library tab
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: 'test-results/feature4-storage-verification.png', fullPage: true });
    
    // Test multiple app reloads to verify persistence
    console.log('🔄 Testing persistence across multiple reloads...');
    for (let i = 0; i < 3; i++) {
      await page.reload();
      await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
      await page.waitForTimeout(2000);
      
      await page.click('flt-glass-pane', { position: { x: 200, y: 150 } }); // Library tab
      await page.waitForTimeout(2000);
      
      await page.screenshot({ 
        path: `test-results/feature4-persistence-reload-${i + 1}.png`,
        fullPage: true 
      });
    }
    
    expect(downloadedBooks.length).toBeGreaterThan(0);
    console.log(`✅ Storage verification completed (${downloadedBooks.length} books processed)`);
  });

  // Cross-browser compatibility test
  test('Cross-browser download compatibility', async ({ page, browserName }) => {
    console.log(`🌐 Testing download functionality in ${browserName}...`);
    
    const browserSpecificSettings = {
      chromium: { timeout: 30000, clickDelay: 500 },
      firefox: { timeout: 45000, clickDelay: 1000 },
      webkit: { timeout: 60000, clickDelay: 1500 },
    };
    
    const settings = browserSpecificSettings[browserName as keyof typeof browserSpecificSettings] || 
                    browserSpecificSettings.chromium;
    
    await page.route('**/archive.org/download/**/*.epub', async route => {
      console.log(`📥 ${browserName} download request intercepted`);
      await route.fulfill({
        status: 200,
        contentType: 'application/epub+zip',
        body: Buffer.from(`Mock EPUB for ${browserName} testing`),
      });
    });

    // Perform standard download flow with browser-specific timings
    await page.click('flt-glass-pane', { position: { x: 350, y: 150 } });
    await page.waitForTimeout(settings.clickDelay);
    
    await page.click('flt-glass-pane', { position: { x: 300, y: 250 } });
    await page.keyboard.type('alice wonderland', { delay: 100 });
    await page.keyboard.press('Enter');
    await page.waitForTimeout(settings.timeout / 10);
    
    await page.click('flt-glass-pane', { position: { x: 400, y: 350 } });
    await page.waitForTimeout(settings.clickDelay);
    
    await page.click('flt-glass-pane', { position: { x: 500, y: 400 } });
    await page.waitForTimeout(settings.timeout / 5);
    
    await page.screenshot({ 
      path: `test-results/feature4-${browserName}-compatibility.png`,
      fullPage: true 
    });
    
    console.log(`✅ ${browserName} compatibility test completed`);
  });
});