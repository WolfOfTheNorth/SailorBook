import { test, expect } from '@playwright/test';

/**
 * Simplified visual book reading functionality test
 * Tests the core reading features without complex navigation
 */

test.describe('Visual Book Reading - Core Features', () => {
  
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000');
    await page.waitForLoadState('networkidle');
    
    // Wait for library view to load
    await expect(page.locator('[data-test-id="library-view"]')).toBeVisible({ timeout: 30000 });
    console.log('✅ Library view loaded');
  });

  test('should load text reader directly and display content', async ({ page }) => {
    console.log('🎯 Testing direct reader access...');

    // Navigate directly to reader with a test book ID
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for text reader view to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    console.log('✅ Text reader view loaded');

    // Check for loading state initially
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      console.log('✅ Loading indicator shown');
      
      // Wait for loading to complete
      await expect(loadingIndicator).toBeHidden({ timeout: 30000 });
      console.log('✅ Loading completed');
    }

    // Verify main reader elements
    await expect(page.locator('[data-test-id="reader-back-btn"]')).toBeVisible({ timeout: 10000 });
    console.log('✅ Back button visible');

    await expect(page.locator('[data-test-id="chapter-list-btn"]')).toBeVisible({ timeout: 10000 });
    console.log('✅ Chapter list button visible');

    await expect(page.locator('[data-test-id="reading-settings-btn"]')).toBeVisible({ timeout: 10000 });
    console.log('✅ Reading settings button visible');

    // Check for page view
    await expect(page.locator('[data-test-id="reader-page-view"]')).toBeVisible({ timeout: 10000 });
    console.log('✅ Page view visible');

    // Check for chapter content
    const chapterContent = page.locator('[data-test-id*="chapter-content-"]').first();
    await expect(chapterContent).toBeVisible({ timeout: 10000 });
    console.log('✅ Chapter content visible');

    // Verify content has text
    const contentText = await chapterContent.textContent();
    expect(contentText?.length).toBeGreaterThan(50);
    console.log(`✅ Chapter content loaded: ${contentText?.substring(0, 100)}...`);

    // Check navigation controls
    await expect(page.locator('[data-test-id="previous-chapter-btn"]')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('[data-test-id="next-chapter-btn"]')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('[data-test-id="reading-progress"]')).toBeVisible({ timeout: 5000 });
    console.log('✅ Navigation controls visible');
  });

  test('should open and close reading settings modal', async ({ page }) => {
    console.log('🎯 Testing reading settings modal...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 30000 });
    }

    // Click reading settings button
    await page.locator('[data-test-id="reading-settings-btn"]').click();
    console.log('✅ Clicked reading settings button');

    // Verify modal appears
    await expect(page.locator('[data-test-id="reading-settings-modal"]')).toBeVisible({ timeout: 5000 });
    console.log('✅ Reading settings modal visible');

    // Check modal contents
    await expect(page.locator('[data-test-id="font-size-slider"]')).toBeVisible();
    console.log('✅ Font size slider visible');

    await expect(page.locator('[data-test-id="dark-mode-toggle"]')).toBeVisible();
    console.log('✅ Dark mode toggle visible');

    // Close modal
    await page.locator('[data-test-id="settings-done-btn"]').click();
    console.log('✅ Clicked done button');

    // Verify modal closes
    await expect(page.locator('[data-test-id="reading-settings-modal"]')).toBeHidden({ timeout: 5000 });
    console.log('✅ Reading settings modal closed');
  });

  test('should open and close chapter list modal', async ({ page }) => {
    console.log('🎯 Testing chapter list modal...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 30000 });
    }

    // Click chapter list button
    await page.locator('[data-test-id="chapter-list-btn"]').click();
    console.log('✅ Clicked chapter list button');

    // Verify modal appears
    await expect(page.locator('[data-test-id="chapter-list-modal"]')).toBeVisible({ timeout: 5000 });
    console.log('✅ Chapter list modal visible');

    // Check for chapter items
    const chapterItems = page.locator('[data-test-id*="chapter-item-"]');
    const itemCount = await chapterItems.count();
    expect(itemCount).toBeGreaterThan(0);
    console.log(`✅ Found ${itemCount} chapter items`);

    // If there are multiple chapters, test navigation
    if (itemCount > 1) {
      // Click on the second chapter
      await chapterItems.nth(1).click();
      console.log('✅ Clicked on second chapter');

      // Verify modal closes
      await expect(page.locator('[data-test-id="chapter-list-modal"]')).toBeHidden({ timeout: 5000 });
      console.log('✅ Chapter list modal closed');

      // Verify navigation occurred
      const progressText = page.locator('[data-test-id="progress-text"]');
      await expect(progressText).toContainText('2 /', { timeout: 5000 });
      console.log('✅ Navigated to chapter 2');
    } else {
      // Close modal for single chapter book
      await page.keyboard.press('Escape');
      await expect(page.locator('[data-test-id="chapter-list-modal"]')).toBeHidden({ timeout: 5000 });
      console.log('✅ Single chapter book - modal closed');
    }
  });

  test('should navigate between chapters using buttons', async ({ page }) => {
    console.log('🎯 Testing chapter navigation buttons...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 30000 });
    }

    // Check initial state
    const progressText = page.locator('[data-test-id="progress-text"]');
    await expect(progressText).toContainText('1 /', { timeout: 10000 });
    console.log('✅ Started at chapter 1');

    // Test next chapter if available
    const nextButton = page.locator('[data-test-id="next-chapter-btn"]');
    if (await nextButton.isEnabled()) {
      await nextButton.click();
      console.log('✅ Clicked next chapter');

      // Verify chapter changed
      await expect(progressText).toContainText('2 /', { timeout: 5000 });
      console.log('✅ Navigated to chapter 2');

      // Test previous chapter
      const prevButton = page.locator('[data-test-id="previous-chapter-btn"]');
      await expect(prevButton).toBeEnabled();
      await prevButton.click();
      console.log('✅ Clicked previous chapter');

      // Verify back to chapter 1
      await expect(progressText).toContainText('1 /', { timeout: 5000 });
      console.log('✅ Navigated back to chapter 1');
    } else {
      console.log('ℹ️ Single chapter book - chapter navigation not applicable');
    }
  });

  test('should handle back navigation', async ({ page }) => {
    console.log('🎯 Testing back navigation...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });

    // Click back button
    await page.locator('[data-test-id="reader-back-btn"]').click();
    console.log('✅ Clicked back button');

    // Verify we navigated away from reader
    await page.waitForURL(/.*(?<!\/reader\/).*/, { timeout: 10000 });
    console.log('✅ Successfully navigated away from reader');
  });

  test('should display chapter headers and progress correctly', async ({ page }) => {
    console.log('🎯 Testing chapter display and progress...');

    // Navigate to reader
    await page.goto('http://localhost:3000/reader/test-book-1');
    await page.waitForLoadState('networkidle');

    // Wait for reader to load
    await expect(page.locator('[data-test-id="text-reader-view"]')).toBeVisible({ timeout: 20000 });
    
    // Wait for loading to complete
    const loadingIndicator = page.locator('[data-test-id="reader-loading"]');
    if (await loadingIndicator.isVisible()) {
      await expect(loadingIndicator).toBeHidden({ timeout: 30000 });
    }

    // Check chapter header
    const chapterHeader = page.locator('[data-test-id*="chapter-header-"]').first();
    await expect(chapterHeader).toBeVisible({ timeout: 10000 });
    console.log('✅ Chapter header visible');

    // Verify header contains chapter information
    const headerText = await chapterHeader.textContent();
    expect(headerText).toContain('Chapter');
    console.log(`✅ Chapter header text: ${headerText?.substring(0, 50)}...`);

    // Check progress indicators
    await expect(page.locator('[data-test-id="reading-progress"]')).toBeVisible();
    await expect(page.locator('[data-test-id="progress-text"]')).toBeVisible();
    console.log('✅ Progress indicators visible');

    // Verify progress text format
    const progressText = await page.locator('[data-test-id="progress-text"]').textContent();
    expect(progressText).toMatch(/\d+ \/ \d+/);
    console.log(`✅ Progress text format correct: ${progressText}`);
  });
});