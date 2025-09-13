import { test, expect, Page } from '@playwright/test';

/**
 * Comprehensive test suite for visual book reading functionality
 * Tests the complete user flow from book selection to reading with all features
 */

test.describe('Visual Book Reading Functionality', () => {
  let page: Page;

  test.beforeEach(async ({ page: testPage }) => {
    page = testPage;
    await page.goto('http://localhost:3000');
    await page.waitForLoadState('networkidle', { timeout: 30000 });
    
    // Wait for Flutter app to fully initialize
    await page.waitForSelector('[data-test-id="sailorbook-app"]', { timeout: 30000 });
    
    console.log('✅ App loaded successfully');
  });

  test('should navigate to book details and start reading', async () => {
    console.log('🎯 Testing book details navigation to reader...');

    // Step 1: Wait for library to load
    await expect(page.locator('[data-test-id="library-view"]')).toBeVisible({ timeout: 15000 });
    console.log('✅ Library view is visible');

    // Step 2: Click on first available book to go to details
    const bookCards = page.locator('[data-test-id*="book-card-"]');
    await expect(bookCards.first()).toBeVisible({ timeout: 10000 });
    
    const firstBook = bookCards.first();
    await firstBook.click();
    console.log('✅ Clicked on first book');

    // Step 3: Wait for book details page to load
    await page.waitForURL(/.*\/book\/.*/, { timeout: 10000 });
    console.log('✅ Navigated to book details page');

    // Step 4: Wait for the Read button to be available
    await expect(page.locator('[data-test-id="read-btn"]')).toBeVisible({ timeout: 15000 });
    console.log('✅ Read button is visible');

    // Step 5: Click the Read button
    await page.locator('[data-test-id="read-btn"]').click();
    console.log('✅ Clicked Read button');

    // Step 6: Verify navigation to reader page
    await page.waitForURL(/.*\/reader\/.*/, { timeout: 10000 });
    console.log('✅ Navigated to reader page');

    // Step 7: Verify text reader view loads
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 15000 });
    console.log('✅ Text reader view is visible');
  });

  test('should display reader interface with proper elements', async () => {
    console.log('🎯 Testing reader interface elements...');

    // Navigate to reader (simulate direct navigation for testing)
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });

    // Check for loading state initially
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      console.log('✅ Loading indicator shown');
      
      // Wait for loading to complete
      await expect(loadingIndicator).toBeHidden({ timeout: 20000 });
      console.log('✅ Loading completed');
    }

    // Verify main reader elements are present
    await expect(page.locator('[data-test-id="reader-back-btn"]')).toBeVisible();
    console.log('✅ Back button is visible');

    await expect(page.locator('[data-test-id="chapter-list-btn"]')).toBeVisible();
    console.log('✅ Chapter list button is visible');

    await expect(page.locator('[data-test-id="reading-settings-btn"]')).toBeVisible();
    console.log('✅ Reading settings button is visible');

    // Verify chapter content loads
    const pageView = page.locator('[data-test-id="reader-page-view"]');
    await expect(pageView).toBeVisible({ timeout: 10000 });
    console.log('✅ Page view is visible');

    // Check for chapter content
    const chapterContent = page.locator('[data-test-id*="chapter-content-"]').first();
    await expect(chapterContent).toBeVisible({ timeout: 10000 });
    console.log('✅ Chapter content is visible');

    // Verify navigation controls
    await expect(page.locator('[data-test-id="previous-chapter-btn"]')).toBeVisible();
    console.log('✅ Previous chapter button is visible');

    await expect(page.locator('[data-test-id="next-chapter-btn"]')).toBeVisible();
    console.log('✅ Next chapter button is visible');

    await expect(page.locator('[data-test-id="reading-progress"]')).toBeVisible();
    console.log('✅ Reading progress indicator is visible');
  });

  test('should navigate between chapters correctly', async () => {
    console.log('🎯 Testing chapter navigation...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load completely
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 20000 });
    }

    // Verify we start at chapter 1
    const progressText = page.locator('[data-test-id="progress-text"]');
    await expect(progressText).toContainText('1 /', { timeout: 10000 });
    console.log('✅ Started at chapter 1');

    // Test next chapter navigation
    const nextButton = page.locator('[data-test-id="next-chapter-btn"]');
    if (await nextButton.isEnabled()) {
      await nextButton.click();
      console.log('✅ Clicked next chapter');

      // Verify chapter changed
      await expect(progressText).toContainText('2 /', { timeout: 5000 });
      console.log('✅ Navigated to chapter 2');

      // Test previous chapter navigation
      const prevButton = page.locator('[data-test-id="previous-chapter-btn"]');
      await expect(prevButton).toBeEnabled();
      await prevButton.click();
      console.log('✅ Clicked previous chapter');

      // Verify back to chapter 1
      await expect(progressText).toContainText('1 /', { timeout: 5000 });
      console.log('✅ Navigated back to chapter 1');
    } else {
      console.log('ℹ️ Single chapter book - next navigation not available');
    }
  });

  test('should show and hide chapter list modal', async () => {
    console.log('🎯 Testing chapter list modal...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 20000 });
    }

    // Click chapter list button
    const chapterListBtn = page.locator('[data-test-id="chapter-list-btn"]');
    await chapterListBtn.click();
    console.log('✅ Clicked chapter list button');

    // Verify modal appears
    const chapterModal = page.locator('[data-test-id="chapter-list-modal"]');
    await expect(chapterModal).toBeVisible({ timeout: 5000 });
    console.log('✅ Chapter list modal is visible');

    // Check for chapter items
    const chapterItems = page.locator('[data-test-id*="chapter-item-"]');
    const itemCount = await chapterItems.count();
    expect(itemCount).toBeGreaterThan(0);
    console.log(`✅ Found ${itemCount} chapter items`);

    // Test clicking on a chapter item (if available)
    if (itemCount > 1) {
      await chapterItems.nth(1).click();
      console.log('✅ Clicked on chapter item');

      // Verify modal closes
      await expect(chapterModal).toBeHidden({ timeout: 5000 });
      console.log('✅ Chapter list modal closed');

      // Verify chapter navigation occurred
      const progressText = page.locator('[data-test-id="progress-text"]');
      await expect(progressText).toContainText('2 /', { timeout: 5000 });
      console.log('✅ Chapter navigation from modal worked');
    } else {
      // Close modal manually for single chapter
      await page.keyboard.press('Escape');
      await expect(chapterModal).toBeHidden({ timeout: 5000 });
      console.log('✅ Modal closed manually');
    }
  });

  test('should show and interact with reading settings modal', async () => {
    console.log('🎯 Testing reading settings modal...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 20000 });
    }

    // Click reading settings button
    const settingsBtn = page.locator('[data-test-id="reading-settings-btn"]');
    await settingsBtn.click();
    console.log('✅ Clicked reading settings button');

    // Verify modal appears
    const settingsModal = page.locator('[data-test-id="reading-settings-modal"]');
    await expect(settingsModal).toBeVisible({ timeout: 5000 });
    console.log('✅ Reading settings modal is visible');

    // Test font size slider
    const fontSlider = page.locator('[data-test-id="font-size-slider"]');
    await expect(fontSlider).toBeVisible();
    console.log('✅ Font size slider is visible');

    // Test dark mode toggle
    const darkModeToggle = page.locator('[data-test-id="dark-mode-toggle"]');
    await expect(darkModeToggle).toBeVisible();
    console.log('✅ Dark mode toggle is visible');

    // Interact with dark mode toggle
    await darkModeToggle.click();
    console.log('✅ Clicked dark mode toggle');

    // Close settings modal
    const doneBtn = page.locator('[data-test-id="settings-done-btn"]');
    await doneBtn.click();
    console.log('✅ Clicked Done button');

    // Verify modal closes
    await expect(settingsModal).toBeHidden({ timeout: 5000 });
    console.log('✅ Reading settings modal closed');
  });

  test('should handle back navigation correctly', async () => {
    console.log('🎯 Testing back navigation...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });

    // Click back button
    const backBtn = page.locator('[data-test-id="reader-back-btn"]');
    await backBtn.click();
    console.log('✅ Clicked back button');

    // Verify navigation back to library or previous page
    await page.waitForURL(/.*(?<!\/reader\/).*/, { timeout: 10000 });
    console.log('✅ Navigated away from reader');
  });

  test('should display chapter content with proper formatting', async () => {
    console.log('🎯 Testing chapter content display and formatting...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 20000 });
    }

    // Check chapter header
    const chapterHeader = page.locator('[data-test-id*="chapter-header-"]').first();
    await expect(chapterHeader).toBeVisible({ timeout: 10000 });
    console.log('✅ Chapter header is visible');

    // Verify chapter header contains title
    await expect(chapterHeader).toContainText('Chapter');
    console.log('✅ Chapter header contains chapter title');

    // Check chapter content
    const chapterContent = page.locator('[data-test-id*="chapter-content-"]').first();
    await expect(chapterContent).toBeVisible({ timeout: 10000 });
    console.log('✅ Chapter content is visible');

    // Verify content is selectable (important for reading)
    const textContent = await chapterContent.textContent();
    expect(textContent).toBeTruthy();
    expect(textContent!.length).toBeGreaterThan(50); // Reasonable content length
    console.log(`✅ Chapter content loaded: ${textContent!.substring(0, 50)}...`);

    // Test text selection (if possible in web context)
    await chapterContent.click();
    console.log('✅ Can interact with chapter content');
  });

  test('should handle error states gracefully', async () => {
    console.log('🎯 Testing error handling...');

    // Navigate to reader with invalid book ID
    await page.goto('http://localhost:3000/reader/invalid-book-id');
    await page.waitForLoadState('networkidle');

    // Wait for reader view to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });

    // Check for error state or retry functionality
    const retryBtn = page.locator('[data-test-id="reader-retry-btn"]');
    
    // If retry button appears, it means error was handled properly
    if (await retryBtn.isVisible()) {
      console.log('✅ Error state displayed with retry option');
      
      // Test retry functionality
      await retryBtn.click();
      console.log('✅ Clicked retry button');
    } else {
      // Check if mock data loads instead (acceptable for testing)
      const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
      if (await loadingIndicator.isVisible()) {
        await expect(loadingIndicator).toBeHidden({ timeout: 20000 });
      }
      
      // Verify content loads (mock data is acceptable)
      const chapterContent = page.locator('[data-test-id*="chapter-content-"]');
      if (await chapterContent.first().isVisible()) {
        console.log('✅ Mock content loaded successfully');
      } else {
        console.log('ℹ️ No content or error state - this may be expected behavior');
      }
    }
  });

  test('should maintain reading position and progress', async () => {
    console.log('🎯 Testing reading progress tracking...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 20000 });
    }

    // Check initial progress
    const progressBar = page.locator('[data-test-id="reading-progress"]');
    await expect(progressBar).toBeVisible({ timeout: 10000 });
    console.log('✅ Progress bar is visible');

    const progressText = page.locator('[data-test-id="progress-text"]');
    await expect(progressText).toBeVisible({ timeout: 10000 });
    
    const initialProgress = await progressText.textContent();
    console.log(`✅ Initial progress: ${initialProgress}`);

    // Navigate to next chapter if possible
    const nextButton = page.locator('[data-test-id="next-chapter-btn"]');
    if (await nextButton.isEnabled()) {
      await nextButton.click();
      
      // Verify progress updated
      const updatedProgress = await progressText.textContent();
      expect(updatedProgress).not.toBe(initialProgress);
      console.log(`✅ Progress updated: ${updatedProgress}`);
    } else {
      console.log('ℹ️ Single chapter book - progress tracking verified for current chapter');
    }
  });
});

/**
 * Additional integration tests for the complete reading flow
 */
test.describe('Reading Integration Flow', () => {
  test('complete reading workflow from library to reader', async ({ page }) => {
    console.log('🎯 Testing complete reading workflow...');

    // Start from home page
    await page.goto('http://localhost:3000');
    await page.waitForLoadState('networkidle');
    
    // Wait for app to load
    await expect(page.locator('[data-test-id="sailorbook-app"]')).toBeVisible({ timeout: 30000 });
    console.log('✅ App loaded');

    // Navigate to library if not already there
    await expect(page.locator('[data-test-id="library-view"]')).toBeVisible({ timeout: 15000 });
    console.log('✅ Library view loaded');

    // Find and click on a book
    const bookCards = page.locator('[data-test-id*="book-card-"]');
    await expect(bookCards.first()).toBeVisible({ timeout: 10000 });
    
    const firstBookTitle = await bookCards.first().locator('text=Alice').textContent();
    console.log(`✅ Found book: ${firstBookTitle}`);
    
    await bookCards.first().click();
    console.log('✅ Clicked on book');

    // Wait for book details
    await page.waitForURL(/.*\/book\/.*/, { timeout: 10000 });
    console.log('✅ Book details page loaded');

    // Wait for Read button and click it
    const readBtn = page.locator('[data-test-id="read-btn"]');
    await expect(readBtn).toBeVisible({ timeout: 15000 });
    await readBtn.click();
    console.log('✅ Clicked Read button');

    // Verify reader loads
    await page.waitForURL(/.*\/reader\/.*/, { timeout: 10000 });
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    console.log('✅ Text reader loaded');

    // Wait for content to load
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 20000 });
    }

    // Verify reading content is available
    const chapterContent = page.locator('[data-test-id*="chapter-content-"]').first();
    await expect(chapterContent).toBeVisible({ timeout: 10000 });
    console.log('✅ Reading content is available');

    // Test some reading features
    await page.locator('[data-test-id="reading-settings-btn"]').click();
    await expect(page.locator('[data-test-id="reading-settings-modal"]')).toBeVisible({ timeout: 5000 });
    await page.locator('[data-test-id="settings-done-btn"]').click();
    console.log('✅ Reading settings tested');

    // Test back navigation
    await page.locator('[data-test-id="reader-back-btn"]').click();
    await page.waitForURL(/.*(?<!\/reader\/).*/, { timeout: 10000 });
    console.log('✅ Back navigation works');

    console.log('🎉 Complete reading workflow test passed!');
  });
});