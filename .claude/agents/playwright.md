# Claude AI Playwright Testing Guide - SailorBook

## 🎭 Overview

This guide provides comprehensive Playwright testing strategies, patterns, and best practices for Claude AI agents working on SailorBook's end-to-end testing. It covers the current test suite, failure analysis, and implementation roadmap.

## 🎯 Current Test Status

### Test Suite Overview (39 Total Tests)
```
✅ Passing Tests (12/39):
├── Basic App Tests (6/6) - Flutter loading, interactions
└── Working Features (6/6) - Architecture, performance

❌ Failing Tests (27/39):
├── App Functionality (0/10) - Missing Flutter UI test IDs
├── E2E Flows (0/7) - Requires API integration
├── Search & Download (0/6) - Needs search implementation
└── Functional Tests (0/10) - Glass pane visibility issues
```

### Critical Path: `FAILED_TESTS_ANALYSIS.md`
**All failing tests are documented** with specific implementation requirements in:
`tests/playwright/FAILED_TESTS_ANALYSIS.md`

## 🛠️ Playwright Configuration

### Project Setup
```typescript
// playwright.config.ts - Current configuration
export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  
  reporter: [
    ['html'],
    ['json', { outputFile: 'test-results/results.json' }],
    ['junit', { outputFile: 'test-results/results.xml' }],
  ],
  
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  
  // Test against multiple browsers
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
    { name: 'Mobile Safari', use: { ...devices['iPhone 12'] } },
  ],
  
  // Automatically start Flutter dev server
  webServer: {
    command: 'cd ../../apps/app_flutter && flutter run -d web-server --web-port=3000',
    port: 3000,
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
  
  globalSetup: require.resolve('./setup/global-setup.ts'),
  globalTeardown: require.resolve('./setup/global-teardown.ts'),
});
```

### Essential Commands
```bash
# Run all tests headlessly
npx playwright test

# Run tests with browser UI (recommended for development)
npx playwright test --headed

# Run specific test file
npx playwright test tests/basic.spec.ts --headed

# Run tests in debug mode
npx playwright test --debug

# Generate test report
npx playwright show-report

# Update test screenshots/videos
npx playwright test --update-snapshots

# Run specific browser
npx playwright test --project=chromium
```

## 🧪 Test Architecture

### Page Object Model Structure
```
tests/playwright/tests/
├── pages/                    # Page Object Models
│   ├── library-page.ts      # Library view interactions
│   ├── book-details-page.ts # Book details interactions
│   └── player-page.ts       # Audio player interactions
├── fixtures/                 # Test data and utilities
│   └── test-data.ts         # Mock API responses
├── utils/                    # Helper utilities
└── *.spec.ts                # Test specifications
```

### Working Test Example
```typescript
// tests/basic.spec.ts - Currently passing
import { test, expect } from '@playwright/test';

test.describe('Basic App Tests', () => {
  test('Flutter app loads and displays correctly', async ({ page }) => {
    console.log('📱 Starting Flutter app test...');
    
    // Navigate and wait for Flutter
    await page.goto('http://localhost:3000');
    await page.waitForSelector('flt-glass-pane', { 
      state: 'attached',
      timeout: 20000 
    });
    
    console.log('🌐 Page loaded, waiting for Flutter...');
    await page.waitForTimeout(3000);
    
    // Verify page title
    const title = await page.title();
    expect(title).toContain('Public-Domain Reader');
    console.log(`📝 Page title: ${title}`);
    
    // Take screenshot for visual validation
    await page.screenshot({ 
      path: 'test-results/flutter-app-working.png', 
      fullPage: true 
    });
    
    console.log('✅ Flutter elements confirmed');
  });
});
```

## 🎭 Page Object Models

### Library Page Pattern
```typescript
// tests/pages/library-page.ts - Needs implementation
import { Page, Locator, expect } from '@playwright/test';

export class LibraryPage {
  readonly page: Page;
  readonly libraryView: Locator;
  readonly emptyLibraryMessage: Locator;
  readonly browseButton: Locator;
  readonly bookCards: Locator;
  readonly searchTab: Locator;
  readonly libraryTab: Locator;

  constructor(page: Page) {
    this.page = page;
    
    // ⚠️ These selectors need Flutter implementation
    this.libraryView = page.locator('[data-testid="library-view"]');
    this.emptyLibraryMessage = page.locator('[data-testid="empty-library"]');
    this.browseButton = page.locator('[data-testid="browse-books"]');
    this.bookCards = page.locator('[data-testid^="book-card-"]');
    this.searchTab = page.locator('[data-testid="search-tab"]');
    this.libraryTab = page.locator('[data-testid="library-tab"]');
  }

  async goto() {
    await this.page.goto('http://localhost:3000');
    await this.waitForLoad();
  }

  async waitForLoad() {
    // ⚠️ Currently fails - needs Flutter implementation
    await this.libraryView.waitFor({ state: 'visible' });
  }

  async switchToSearchTab() {
    await this.searchTab.click();
    await this.page.waitForTimeout(1000);
  }

  async switchToLibraryTab() {
    await this.libraryTab.click();
    await this.page.waitForTimeout(1000);
  }

  async expectEmptyLibrary() {
    await expect(this.emptyLibraryMessage).toBeVisible();
    await expect(this.browseButton).toBeVisible();
  }

  async expectBooksInLibrary(count: number) {
    await expect(this.bookCards).toHaveCount(count);
  }

  // Search functionality
  async searchForBooks(query: string) {
    const searchInput = this.page.locator('[data-testid="search-input"]');
    await searchInput.fill(query);
    await searchInput.press('Enter');
    await this.page.waitForTimeout(2000);
  }

  async expectSearchResults(count: number) {
    const searchResults = this.page.locator('[data-testid^="search-result-"]');
    await expect(searchResults).toHaveCount(count);
  }

  async openFirstBook() {
    await this.bookCards.first().click();
  }

  async downloadFirstBook() {
    const firstDownloadBtn = this.page.locator('[data-testid^="download-btn-"]').first();
    await firstDownloadBtn.click();
    await this.page.waitForTimeout(2000);
  }

  async playFirstBook() {
    const firstListenBtn = this.page.locator('[data-testid^="listen-btn-"]').first();
    await firstListenBtn.click();
  }

  async getSearchResults() {
    return await this.bookCards.all();
  }
}
```

### Book Details Page Pattern
```typescript
// tests/pages/book-details-page.ts - Needs implementation
export class BookDetailsPage {
  readonly page: Page;
  readonly bookTitle: Locator;
  readonly downloadButton: Locator;
  readonly listenButton: Locator;
  readonly chaptersList: Locator;
  readonly backButton: Locator;

  constructor(page: Page) {
    this.page = page;
    
    // ⚠️ These need Flutter implementation with test IDs
    this.bookTitle = page.locator('[data-testid="book-title"]');
    this.downloadButton = page.locator('[data-testid="download-btn"]');
    this.listenButton = page.locator('[data-testid="listen-btn"]');
    this.chaptersList = page.locator('[data-testid="chapters-list"]');
    this.backButton = page.locator('[data-testid="back-btn"]');
  }

  async waitForLoad() {
    await this.bookTitle.waitFor({ state: 'visible' });
  }

  async expectBookTitle(title: string) {
    await expect(this.bookTitle).toContainText(title);
  }

  async expectDownloadButton() {
    await expect(this.downloadButton).toBeVisible();
  }

  async expectListenButton() {
    await expect(this.listenButton).toBeVisible();
  }

  async expectChapters(count: number) {
    const chapters = this.chaptersList.locator('[data-testid^="chapter-"]');
    await expect(chapters).toHaveCount(count);
  }

  async downloadBook() {
    await this.downloadButton.click();
    // Wait for download to complete
    await this.page.waitForTimeout(3000);
  }

  async startListening() {
    await this.listenButton.click();
  }

  async goBack() {
    await this.backButton.click();
  }
}
```

### Player Page Pattern
```typescript
// tests/pages/player-page.ts - Needs implementation
export class PlayerPage {
  readonly page: Page;
  readonly playPauseButton: Locator;
  readonly nextParagraphButton: Locator;
  readonly speedSelector: Locator;
  readonly chapterInfo: Locator;
  readonly voiceSettingsButton: Locator;

  constructor(page: Page) {
    this.page = page;
    
    // ⚠️ These need Flutter implementation with test IDs
    this.playPauseButton = page.locator('[data-testid="play-pause-btn"]');
    this.nextParagraphButton = page.locator('[data-testid="next-paragraph-btn"]');
    this.speedSelector = page.locator('[data-testid="speed-selector"]');
    this.chapterInfo = page.locator('[data-testid="chapter-info"]');
    this.voiceSettingsButton = page.locator('[data-testid="voice-settings-btn"]');
  }

  async waitForLoad() {
    await this.playPauseButton.waitFor({ state: 'visible' });
  }

  async play() {
    await this.playPauseButton.click();
  }

  async pause() {
    await this.playPauseButton.click();
  }

  async nextParagraph() {
    await this.nextParagraphButton.click();
  }

  async setSpeed(speed: string) {
    await this.page.selectOption(this.speedSelector, speed);
  }

  async expectPlaying() {
    // Check if pause icon is showing (indicating playing state)
    await expect(this.playPauseButton.locator('icon[data-icon="pause"]')).toBeVisible();
  }

  async expectStopped() {
    // Check if play icon is showing (indicating stopped state)
    await expect(this.playPauseButton.locator('icon[data-icon="play"]')).toBeVisible();
  }

  async expectSpeed(speed: string) {
    await expect(this.speedSelector).toHaveValue(speed);
  }

  async waitForParagraphChange() {
    await this.page.waitForTimeout(1000);
  }

  async openVoiceSettings() {
    await this.voiceSettingsButton.click();
  }

  async goBack() {
    await this.page.goBack();
  }
}
```

## 🎨 Working with Flutter Web

### Flutter Element Interaction Patterns
```typescript
// Current working pattern for Flutter web
test('Flutter interaction patterns', async ({ page }) => {
  await page.goto('http://localhost:3000');
  
  // Wait for Flutter to load
  await page.waitForSelector('flt-glass-pane', { 
    state: 'attached',
    timeout: 20000 
  });
  await page.waitForTimeout(3000);
  
  // ✅ Method 1: Direct coordinate clicking (currently working)
  await page.click('flt-glass-pane', { position: { x: 960, y: 78 } }); // Search tab
  
  // ❌ Method 2: Test ID selectors (needs implementation)
  // await page.click('[data-testid="search-tab"]');
  
  // ✅ Method 3: Canvas interaction for Flutter web
  const canvas = page.locator('canvas').first();
  await canvas.click({ position: { x: 400, y: 300 } });
  
  // ✅ Method 4: Keyboard input (works with focused elements)
  await page.keyboard.type('search query');
  await page.keyboard.press('Enter');
});
```

### Flutter App State Detection
```typescript
// Helper function to wait for Flutter app readiness
async function waitForFlutterApp(page: Page) {
  // Wait for glass pane to be attached
  await page.waitForSelector('flt-glass-pane', { 
    state: 'attached',
    timeout: 30000 
  });
  
  // Wait for Flutter to finish initial render
  await page.waitForTimeout(3000);
  
  // Verify Flutter is interactive
  const isInteractive = await page.evaluate(() => {
    const glassPane = document.querySelector('flt-glass-pane');
    return glassPane && 
           window.getComputedStyle(glassPane).visibility !== 'hidden' &&
           document.querySelectorAll('canvas').length > 0;
  });
  
  if (!isInteractive) {
    throw new Error('Flutter app is not interactive');
  }
}
```

## 🔧 Test Data & Mocking

### API Response Mocking
```typescript
// tests/fixtures/test-data.ts - Current implementation
export const mockApiResponses = {
  searchBooks: {
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
        title: 'The Adventures of Tom Sawyer', 
        author_name: ['Mark Twain'],
        cover_i: 789012,
        first_publish_year: 1876,
        ia: ['tom-sawyer-001'],
        language: ['eng'],
        subject: ['Adventure', 'Children\'s literature']
      }
    ]
  }
};

export const testManifest = {
  books: [
    {
      id: 'test-book-1',
      title: 'Alice\'s Adventures in Wonderland',
      author: 'Lewis Carroll',
      chapters: [
        { id: 0, title: 'Chapter 1: Down the Rabbit Hole', paragraphs: 15 },
        { id: 1, title: 'Chapter 2: The Pool of Tears', paragraphs: 12 },
        { id: 2, title: 'Chapter 3: A Caucus-Race', paragraphs: 18 }
      ],
      downloadedAt: new Date().toISOString(),
      lastPosition: null
    }
  ]
};
```

### Test Setup & Teardown
```typescript
// tests/setup/global-setup.ts - Current implementation
async function globalSetup() {
  console.log('🚀 Starting global test setup...');
  
  // Wait for Flutter app to be available
  console.log('📱 Waiting for Flutter web app...');
  const response = await fetch('http://localhost:3000');
  if (!response.ok) {
    throw new Error('Flutter app not available');
  }
  console.log('✅ Flutter app loaded successfully');
  
  // Set up test data
  console.log('📊 Setting up test data...');
  // Initialize any required test state
  console.log('✅ Test data setup complete');
  
  console.log('✅ Global test setup complete');
}
```

### Per-Test Setup Pattern
```typescript
// Common test setup pattern
test.describe('E2E User Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Mock API responses
    await page.route('**/search.json*', async route => {
      await route.fulfill({
        contentType: 'application/json',
        body: JSON.stringify(mockApiResponses.searchBooks),
      });
    });

    await page.route('**/download/**', async route => {
      await route.fulfill({
        contentType: 'application/epub+zip',
        body: Buffer.from('mock epub content'),
      });
    });

    // Set up native bridge mocks
    await page.evaluate(() => {
      // @ts-ignore
      window.buildManifest = () => Promise.resolve(testManifest);
      // @ts-ignore
      window.synthesize = () => Promise.resolve(new Array(1000).fill(0));
    });

    // Navigate to app
    await page.goto('http://localhost:3000');
    await waitForFlutterApp(page);
  });
});
```

## 📊 Test Execution & Reporting

### CI/CD Integration
```yaml
# .github/workflows/playwright.yml
name: Playwright Tests
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: 18
    - name: Install dependencies
      run: npm ci
      working-directory: tests/playwright
    - name: Install Playwright Browsers
      run: npx playwright install --with-deps
      working-directory: tests/playwright
    - name: Run Playwright tests
      run: npx playwright test
      working-directory: tests/playwright
    - uses: actions/upload-artifact@v4
      if: always()
      with:
        name: playwright-report
        path: tests/playwright/playwright-report/
        retention-days: 30
```

### Test Result Analysis
```typescript
// Custom test reporter
class SailorBookReporter implements Reporter {
  onTestEnd(test: TestCase, result: TestResult) {
    const status = result.status;
    const testPath = test.location.file;
    const testName = test.title;
    
    if (status === 'failed' && testPath.includes('functionality')) {
      console.log(`❌ FUNCTIONALITY TEST FAILED: ${testName}`);
      console.log(`💡 Check FAILED_TESTS_ANALYSIS.md for implementation requirements`);
    } else if (status === 'passed') {
      console.log(`✅ ${testName}`);
    }
  }
  
  onEnd(result: FullResult) {
    const { status, startTime, duration } = result;
    const passedCount = result.passed || 0;
    const failedCount = result.failed || 0;
    const totalCount = passedCount + failedCount;
    
    console.log('\n📊 Test Summary:');
    console.log(`   Total: ${totalCount}`);
    console.log(`   Passed: ${passedCount} ✅`);
    console.log(`   Failed: ${failedCount} ❌`);
    console.log(`   Duration: ${duration}ms`);
    
    if (failedCount > 0) {
      console.log('\n📋 Next Steps:');
      console.log('   1. Review FAILED_TESTS_ANALYSIS.md');
      console.log('   2. Implement missing Flutter UI test IDs');
      console.log('   3. Add search API integration');
      console.log('   4. Re-run tests to verify fixes');
    }
  }
}
```

## 🚨 Common Issues & Solutions

### Issue: Flutter Glass Pane Not Visible
```typescript
// ❌ Failing pattern
await page.click('[data-testid="search-tab"]'); // Element not found

// ✅ Current workaround
await page.click('flt-glass-pane', { position: { x: 960, y: 78 } });

// 🎯 Target solution (requires Flutter implementation)
// Add to Flutter widget:
Tab(
  key: const Key('search-tab'),
  child: Semantics(
    identifier: 'search-tab',
    child: const Text('Search'),
  ),
)
```

### Issue: Timing and Race Conditions
```typescript
// ❌ Race condition prone
await page.click('button');
expect(page.locator('result')).toBeVisible(); // May fail

// ✅ Proper waiting
await page.click('button');
await page.waitForSelector('result', { state: 'visible' });
expect(page.locator('result')).toBeVisible();

// ✅ Using waitFor
await page.click('button');
await expect(page.locator('result')).toBeVisible({ timeout: 10000 });
```

### Issue: Network Request Mocking
```typescript
// ✅ Comprehensive network mocking
test.beforeEach(async ({ page }) => {
  // Mock successful search
  await page.route('**/search.json*', async (route) => {
    const url = route.request().url();
    const query = new URL(url).searchParams.get('q');
    
    // Dynamic responses based on query
    const response = query?.includes('alice') 
      ? mockApiResponses.searchBooks
      : { docs: [] };
    
    await route.fulfill({
      contentType: 'application/json',
      body: JSON.stringify(response),
    });
  });
  
  // Mock download endpoints
  await page.route('**/download/**', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/epub+zip',
      body: Buffer.from('Mock EPUB content'),
    });
  });
  
  // Mock error scenarios when needed
  if (testName.includes('error')) {
    await page.route('**/search.json*', route => route.abort());
  }
});
```

## 📋 Implementation Priority

### Phase 1: Critical Fixes (Required for 27 failing tests)
1. **Flutter Glass Pane Visibility**
   ```dart
   // Add to main Flutter app
   MaterialApp(
     builder: (context, child) => Semantics(
       container: true,
       identifier: 'app-container',
       child: child,
     ),
   )
   ```

2. **Test ID Implementation**
   ```dart
   // Add to all interactive widgets
   ElevatedButton(
     key: const Key('download-btn'),
     child: const Text('Download'),
   )
   ```

### Phase 2: API Integration (E2E Tests)
3. **Search Implementation** - `BookService.searchBooks()`
4. **Download Implementation** - `BookService.downloadBook()`
5. **Player Integration** - Audio playback controls

### Phase 3: Advanced Features
6. **Voice Settings** - TTS voice selection
7. **Offline Mode** - Local storage testing
8. **Multi-book Management** - Library organization

## 📚 Resources & Documentation

### Playwright Resources
- [Playwright Documentation](https://playwright.dev/)
- [Flutter Web Testing Guide](https://docs.flutter.dev/cookbook/testing/integration/introduction)
- [Page Object Model](https://playwright.dev/docs/pom)

### Project-Specific Resources
- `FAILED_TESTS_ANALYSIS.md` - Implementation roadmap
- `CLAUDE_UI_UX.md` - UI component patterns
- `CLAUDE_TESTING.md` - Unit testing strategies

### Debug Commands
```bash
# Debug specific test
npx playwright test tests/basic.spec.ts --debug

# Generate code for interactions
npx playwright codegen http://localhost:3000

# Run with trace viewer
npx playwright test --trace on
npx playwright show-trace trace.zip

# Check test results
npx playwright show-report
```

---

**Last Updated**: 2025-08-28  
**Status**: Active Development  
**Priority**: Implement Flutter UI test IDs to fix 27 failing tests

*Follow this guide to maintain and expand SailorBook's comprehensive E2E testing suite.*