import { test, expect } from '@playwright/test';
import { LibraryPage } from './pages/library-page';
import { mockApiResponses } from './fixtures/test-data';

test.describe('Library', () => {
  let libraryPage: LibraryPage;

  test.beforeEach(async ({ page }) => {
    libraryPage = new LibraryPage(page);
    
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

    await libraryPage.goto();
  });

  test('should display empty library initially', async () => {
    await libraryPage.expectEmptyLibrary();
  });

  test('should show search tab and allow searching', async () => {
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice wonderland');
    await libraryPage.expectSearchResults(1);
  });

  test('should display book cards with correct information', async () => {
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice');
    
    const bookCards = await libraryPage.getSearchResults();
    expect(bookCards.length).toBeGreaterThan(0);
    
    // Check first book card content
    const firstCard = bookCards[0];
    await expect(firstCard.locator('[data-testid="book-title"]'))
      .toContainText('Alice\'s Adventures in Wonderland');
    await expect(firstCard.locator('[data-testid="book-author"]'))
      .toContainText('Lewis Carroll');
  });

  test('should allow downloading a book', async () => {
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice');
    
    // Mock the native bridge calls
    await libraryPage.page.evaluate(() => {
      // @ts-ignore
      window.buildManifest = () => Promise.resolve({
        bookId: 'test-book-1',
        title: 'Alice\'s Adventures in Wonderland',
        author: 'Lewis Carroll',
        chapters: [],
        paragraphs: [],
      });
      // @ts-ignore
      window.saveManifest = () => Promise.resolve();
    });
    
    await libraryPage.downloadFirstBook();
    
    // Switch to library tab and verify book appears
    await libraryPage.switchToLibraryTab();
    await libraryPage.expectBooksInLibrary(1);
  });

  test('should navigate to book details when clicking on a book', async () => {
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice');
    await libraryPage.openFirstBook();
    
    // Verify navigation to book details page
    await expect(libraryPage.page).toHaveURL(/\/book\//);
    await libraryPage.page.waitForSelector('[data-testid="book-details-view"]');
  });

  test('should navigate to settings', async () => {
    await libraryPage.goToSettings();
    await expect(libraryPage.page).toHaveURL(/\/settings/);
  });

  test('should handle search errors gracefully', async () => {
    // Mock API error
    await libraryPage.page.route('**/search.json*', async route => {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal server error' }),
      });
    });

    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('error');
    
    // Verify error message is displayed
    await expect(libraryPage.page.locator('[data-testid="error-message"]'))
      .toBeVisible();
  });

  test('should clear search when search input is cleared', async () => {
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice');
    await libraryPage.expectSearchResults(1);
    
    // Clear search
    await libraryPage.searchInput.clear();
    await libraryPage.searchInput.press('Enter');
    
    // Verify search results are cleared
    await expect(libraryPage.page.locator('[data-testid="empty-search-state"]'))
      .toBeVisible();
  });
});