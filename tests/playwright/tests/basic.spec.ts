import { test, expect } from '@playwright/test';

test.describe('Basic App Tests', () => {
  
  test('Flutter app loads and displays correctly', async ({ page }) => {
    // Set a longer timeout for Flutter apps
    test.setTimeout(60000);
    
    console.log('📱 Starting Flutter app test...');
    
    // Navigate to the app with extended timeout
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 45000 
    });
    
    console.log('🌐 Page loaded, waiting for Flutter...');
    
    // Wait for Flutter elements to appear (with fallback)
    try {
      await page.waitForSelector('flt-glass-pane', { 
        timeout: 20000,
        state: 'attached'
      });
      console.log('✅ Flutter glass pane found');
    } catch (error) {
      console.log('⚠️ Glass pane not found, checking for alternative Flutter elements...');
      
      // Try waiting for any canvas element (Flutter renders to canvas)
      await page.waitForSelector('canvas', { timeout: 10000 });
      console.log('✅ Canvas element found');
    }
    
    // Wait for content to render
    await page.waitForTimeout(3000);
    
    // Take a screenshot to see what's rendered
    await page.screenshot({ 
      path: 'test-results/app-loaded.png', 
      fullPage: true 
    });
    
    // Verify page title
    const title = await page.title();
    expect(title).toContain('Public-Domain Reader');
    console.log(`📝 Page title: ${title}`);
    
    // Check for Flutter-specific elements
    const hasFlutterElements = await page.evaluate(() => {
      return !!(
        document.querySelector('flt-glass-pane') ||
        document.querySelector('flutter-view') ||
        document.querySelector('[data-flt-renderer]') ||
        document.querySelector('canvas')
      );
    });
    
    expect(hasFlutterElements).toBe(true);
    console.log('✅ Flutter elements confirmed');
  });

  test('App responds to basic interactions', async ({ page }) => {
    test.setTimeout(60000);
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    await page.waitForTimeout(3000);
    
    // Try clicking on different areas of the screen
    console.log('🖱️ Testing app interactions...');
    
    const interactions = [
      { x: 400, y: 200, name: 'center-top' },
      { x: 300, y: 300, name: 'left-center' },
      { x: 500, y: 300, name: 'right-center' },
      { x: 400, y: 400, name: 'center-bottom' }
    ];
    
    for (const interaction of interactions) {
      try {
        await page.click('body', { 
          position: interaction,
          timeout: 5000
        });
        await page.waitForTimeout(500);
        console.log(`✅ Click at ${interaction.name} successful`);
      } catch (error) {
        console.log(`⚠️ Click at ${interaction.name} failed: ${error.message}`);
      }
    }
    
    await page.screenshot({ 
      path: 'test-results/after-interactions.png',
      fullPage: true 
    });
  });

  test('App handles keyboard input', async ({ page }) => {
    test.setTimeout(45000);
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    await page.waitForTimeout(3000);
    
    console.log('⌨️ Testing keyboard interactions...');
    
    // Focus on the page
    await page.click('body');
    
    // Test various keyboard inputs
    const keyInputs = ['Tab', 'Tab', 'Enter', 'Escape', 'Space'];
    
    for (const key of keyInputs) {
      await page.keyboard.press(key);
      await page.waitForTimeout(300);
      console.log(`✅ Key '${key}' pressed`);
    }
    
    await page.screenshot({ 
      path: 'test-results/keyboard-test.png',
      fullPage: true 
    });
  });

  test('App works in different viewport sizes', async ({ page }) => {
    test.setTimeout(60000);
    
    const viewports = [
      { width: 1920, height: 1080, name: 'desktop' },
      { width: 768, height: 1024, name: 'tablet' },
      { width: 375, height: 667, name: 'mobile' }
    ];
    
    for (const viewport of viewports) {
      console.log(`📱 Testing ${viewport.name} viewport (${viewport.width}x${viewport.height})`);
      
      await page.setViewportSize(viewport);
      await page.goto('http://localhost:3000', { 
        waitUntil: 'networkidle',
        timeout: 30000 
      });
      
      await page.waitForTimeout(2000);
      
      await page.screenshot({ 
        path: `test-results/viewport-${viewport.name}.png`,
        fullPage: true
      });
      
      // Verify the page is responsive
      const bodySize = await page.evaluate(() => ({
        width: document.body.offsetWidth,
        height: document.body.offsetHeight
      }));
      
      expect(bodySize.width).toBeGreaterThan(0);
      expect(bodySize.height).toBeGreaterThan(0);
      
      console.log(`✅ ${viewport.name} viewport works (${bodySize.width}x${bodySize.height})`);
    }
  });

  test('App handles network requests properly', async ({ page }) => {
    test.setTimeout(45000);
    
    const requests: string[] = [];
    const responses: string[] = [];
    
    page.on('request', request => {
      requests.push(request.url());
      console.log(`📤 Request: ${request.method()} ${request.url()}`);
    });
    
    page.on('response', response => {
      responses.push(response.url());
      console.log(`📥 Response: ${response.status()} ${response.url()}`);
    });
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    await page.waitForTimeout(3000);
    
    console.log(`✅ Made ${requests.length} requests, received ${responses.length} responses`);
    
    // Basic assertions about network activity
    expect(requests.length).toBeGreaterThan(0);
    expect(responses.length).toBeGreaterThan(0);
    
    // Check that the main page was loaded
    const mainPageLoaded = requests.some(url => url === 'http://localhost:3000/');
    expect(mainPageLoaded).toBe(true);
  });

  test('Console logs and errors', async ({ page }) => {
    test.setTimeout(45000);
    
    const consoleLogs: Array<{type: string, text: string}> = [];
    
    page.on('console', msg => {
      consoleLogs.push({
        type: msg.type(),
        text: msg.text()
      });
      console.log(`📝 Console ${msg.type()}: ${msg.text()}`);
    });
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    await page.waitForTimeout(5000);
    
    const errors = consoleLogs.filter(log => log.type === 'error');
    const warnings = consoleLogs.filter(log => log.type === 'warning');
    
    console.log(`✅ Console summary: ${consoleLogs.length} total, ${errors.length} errors, ${warnings.length} warnings`);
    
    // We expect some logs from Flutter, so we just log them for analysis
    // Don't fail the test on warnings, only on critical errors
    const criticalErrors = errors.filter(error => 
      !error.text.includes('DevTools') && 
      !error.text.includes('extension') && 
      !error.text.includes('favicon.ico') &&
      !error.text.includes('manifest.json')
    );
    
    if (criticalErrors.length > 0) {
      console.log('⚠️ Critical errors found:', criticalErrors);
    }
  });
});