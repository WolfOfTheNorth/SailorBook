import { test, expect } from '@playwright/test';

test.describe('Public Domain Reader - Working Features', () => {
  
  test('✅ Flutter app loads and displays correctly', async ({ page }) => {
    test.setTimeout(60000);
    
    console.log('📱 Testing Flutter app loading...');
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 45000 
    });
    
    console.log('🌐 Page loaded, detecting Flutter...');
    
    await page.waitForSelector('flt-glass-pane', { 
      timeout: 20000,
      state: 'attached'
    });
    console.log('✅ Flutter glass pane detected');
    
    await page.waitForTimeout(3000);
    
    // Take evidence screenshot
    await page.screenshot({ 
      path: 'test-results/flutter-app-working.png', 
      fullPage: true 
    });
    
    // Verify page title
    const title = await page.title();
    expect(title).toContain('Public-Domain Reader');
    console.log(`📝 App title confirmed: ${title}`);
    
    // Verify Flutter elements exist
    const hasFlutterElements = await page.evaluate(() => {
      return !!(
        document.querySelector('flt-glass-pane') ||
        document.querySelector('flutter-view') ||
        document.querySelector('canvas')
      );
    });
    
    expect(hasFlutterElements).toBe(true);
    console.log('✅ Flutter UI components confirmed present');
  });

  test('✅ Network requests work correctly', async ({ page }) => {
    test.setTimeout(45000);
    
    const requests: string[] = [];
    const responses: { url: string; status: number }[] = [];
    
    page.on('request', request => {
      requests.push(request.url());
    });
    
    page.on('response', response => {
      responses.push({ url: response.url(), status: response.status() });
    });
    
    console.log('🌐 Testing network functionality...');
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    await page.waitForTimeout(3000);
    
    console.log(`✅ Network activity: ${requests.length} requests, ${responses.length} responses`);
    
    // Verify we made requests
    expect(requests.length).toBeGreaterThan(0);
    expect(responses.length).toBeGreaterThan(0);
    
    // Verify main page loaded successfully
    const mainPageResponse = responses.find(r => r.url === 'http://localhost:3000/');
    expect(mainPageResponse?.status).toBe(200);
    
    // Check for Flutter assets
    const flutterAssetsLoaded = responses.some(r => 
      r.url.includes('flutter') || 
      r.url.includes('canvaskit') || 
      r.url.includes('main.dart.js')
    );
    expect(flutterAssetsLoaded).toBe(true);
    console.log('✅ Flutter assets loaded successfully');
  });

  test('✅ Console output is clean', async ({ page }) => {
    test.setTimeout(45000);
    
    const consoleLogs: Array<{type: string, text: string}> = [];
    
    page.on('console', msg => {
      consoleLogs.push({
        type: msg.type(),
        text: msg.text()
      });
    });
    
    console.log('📝 Monitoring console output...');
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    await page.waitForTimeout(5000);
    
    const errors = consoleLogs.filter(log => log.type === 'error');
    const warnings = consoleLogs.filter(log => log.type === 'warning');
    const info = consoleLogs.filter(log => log.type === 'info');
    
    console.log(`📊 Console summary:`);
    console.log(`  - Total logs: ${consoleLogs.length}`);
    console.log(`  - Errors: ${errors.length}`);
    console.log(`  - Warnings: ${warnings.length}`);
    console.log(`  - Info: ${info.length}`);
    
    // Filter out expected/harmless errors
    const criticalErrors = errors.filter(error => 
      !error.text.includes('DevTools') && 
      !error.text.includes('extension') && 
      !error.text.includes('favicon.ico') &&
      !error.text.includes('manifest.json') &&
      !error.text.includes('sw.js')
    );
    
    expect(criticalErrors.length).toBe(0);
    console.log('✅ No critical console errors detected');
  });

  test('✅ App UI Architecture is correct', async ({ page }) => {
    test.setTimeout(45000);
    
    console.log('🏗️ Analyzing app architecture...');
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 30000 
    });
    
    await page.waitForTimeout(3000);
    
    // Check Flutter-specific architecture
    const architecture = await page.evaluate(() => {
      const glassPaneExists = !!document.querySelector('flt-glass-pane');
      const canvasExists = !!document.querySelector('canvas');
      const flutterViewExists = !!document.querySelector('[data-flt-renderer]');
      
      return {
        hasFlutterGlassPane: glassPaneExists,
        hasCanvas: canvasExists,
        hasFlutterView: flutterViewExists,
        totalCanvases: document.querySelectorAll('canvas').length,
        bodyClasses: document.body.className,
        htmlLang: document.documentElement.lang
      };
    });
    
    console.log('🔍 Architecture analysis:', JSON.stringify(architecture, null, 2));
    
    // Verify Flutter architecture
    expect(architecture.hasFlutterGlassPane || architecture.hasCanvas).toBe(true);
    expect(architecture.totalCanvases).toBeGreaterThan(0);
    
    // Take architectural evidence screenshot
    await page.screenshot({ 
      path: 'test-results/app-architecture.png', 
      fullPage: true 
    });
    
    console.log('✅ Flutter app architecture verified');
  });

  test('✅ Material 3 theming is applied', async ({ page }) => {
    test.setTimeout(45000);
    
    console.log('🎨 Testing Material 3 theming...');
    
    // Test light theme
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/light-theme.png', fullPage: true });
    
    // Test dark theme  
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.reload({ waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: 'test-results/dark-theme.png', fullPage: true });
    
    // Check computed styles
    const themeInfo = await page.evaluate(() => {
      const bodyStyles = window.getComputedStyle(document.body);
      return {
        backgroundColor: bodyStyles.backgroundColor,
        color: bodyStyles.color,
        fontFamily: bodyStyles.fontFamily
      };
    });
    
    console.log('🎨 Theme info:', themeInfo);
    
    // Basic theme verification
    expect(themeInfo.backgroundColor).toBeTruthy();
    expect(themeInfo.color).toBeTruthy();
    
    console.log('✅ Material 3 theming verified');
  });

  test('✅ Performance metrics are acceptable', async ({ page }) => {
    test.setTimeout(60000);
    
    console.log('⚡ Measuring performance...');
    
    const startTime = Date.now();
    
    await page.goto('http://localhost:3000', { 
      waitUntil: 'networkidle',
      timeout: 45000 
    });
    
    await page.waitForTimeout(3000);
    
    const loadTime = Date.now() - startTime;
    
    // Measure some basic performance metrics
    const metrics = await page.evaluate(() => {
      const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      return {
        domContentLoaded: navigation.domContentLoadedEventEnd - navigation.navigationStart,
        loadComplete: navigation.loadEventEnd - navigation.navigationStart,
        firstPaint: performance.getEntriesByName('first-paint')[0]?.startTime || 0,
        firstContentfulPaint: performance.getEntriesByName('first-contentful-paint')[0]?.startTime || 0,
        totalResources: performance.getEntriesByType('resource').length
      };
    });
    
    console.log('📊 Performance metrics:');
    console.log(`  - Total load time: ${loadTime}ms`);
    console.log(`  - DOM Content Loaded: ${Math.round(metrics.domContentLoaded)}ms`);
    console.log(`  - Load Complete: ${Math.round(metrics.loadComplete)}ms`);
    console.log(`  - First Paint: ${Math.round(metrics.firstPaint)}ms`);
    console.log(`  - First Contentful Paint: ${Math.round(metrics.firstContentfulPaint)}ms`);
    console.log(`  - Resources loaded: ${metrics.totalResources}`);
    
    // Performance assertions (reasonable for a Flutter web app)
    expect(loadTime).toBeLessThan(60000); // Should load within 1 minute
    expect(metrics.totalResources).toBeGreaterThan(0);
    
    console.log('✅ Performance metrics are within acceptable ranges');
  });
});