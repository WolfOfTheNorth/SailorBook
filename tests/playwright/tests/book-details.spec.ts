import { test, expect } from '@playwright/test';
import { LibraryPage } from './pages/library-page';
import { BookDetailsPage } from './pages/book-details-page';
import { mockApiResponses, testManifest } from './fixtures/test-data';

test.describe('Book Details', () => {
  let libraryPage: LibraryPage;
  let bookDetailsPage: BookDetailsPage;

  test.beforeEach(async ({ page }) => {
    libraryPage = new LibraryPage(page);
    bookDetailsPage = new BookDetailsPage(page);
    
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

    // Mock native bridge calls
    await page.evaluate(() => {
      // @ts-ignore
      window.buildManifest = () => Promise.resolve(testManifest);
      // @ts-ignore
      window.loadManifest = () => Promise.resolve(testManifest);
      // @ts-ignore
      window.saveManifest = () => Promise.resolve();
    });

    await libraryPage.goto();
  });

  test('should display book details correctly', async () => {
    // Navigate to a book details page
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();

    await bookDetailsPage.expectBookTitle('Alice\'s Adventures in Wonderland');
    await bookDetailsPage.expectBookAuthor('Lewis Carroll');
    await bookDetailsPage.expectBookStats();
  });

  test('should show download button for undownloaded books', async () => {
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();
    
    await bookDetailsPage.expectDownloadButton();
  });

  test('should show listen and read buttons for downloaded books', async () => {
    // Mock as downloaded book
    await page.evaluate(() => {
      // @ts-ignore
      window.isBookDownloaded = () => true;
    });
    
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();
    
    await bookDetailsPage.expectListenButton();
    await bookDetailsPage.expectReadButton();
  });

  test('should display chapters list for downloaded books', async () => {
    await page.evaluate(() => {
      // @ts-ignore
      window.isBookDownloaded = () => true;
    });
    
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();
    
    await bookDetailsPage.expectChapters(3); // testManifest has 3 chapters
  });

  test('should download book when download button is clicked', async () => {
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();
    
    await bookDetailsPage.downloadBook();
    
    // Verify download completed and buttons changed
    await bookDetailsPage.expectListenButton();
    await bookDetailsPage.expectReadButton();
  });

  test('should navigate to player when listen button is clicked', async () => {
    await page.evaluate(() => {
      // @ts-ignore
      window.isBookDownloaded = () => true;
    });
    
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();
    
    await bookDetailsPage.startListening();
    
    await expect(page).toHaveURL(/\/player\//);
  });

  test('should show coming soon message for read button', async () => {
    await page.evaluate(() => {
      // @ts-ignore
      window.isBookDownloaded = () => true;
    });
    
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();
    
    await bookDetailsPage.startReading();
    
    // Verify snackbar message
    await expect(page.locator('text=Reading mode coming in v0.1'))
      .toBeVisible();
  });

  test('should play specific chapter when chapter play button is clicked', async () => {
    await page.evaluate(() => {
      // @ts-ignore
      window.isBookDownloaded = () => true;
    });
    
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();
    
    await bookDetailsPage.playChapter(1);
    
    await expect(page).toHaveURL(/\/player\//);
  });

  test('should navigate back to library', async () => {
    await page.goto('/book/test-book-1');
    await bookDetailsPage.waitForLoad();
    
    await bookDetailsPage.goBack();
    
    await expect(page).toHaveURL('/');
  });

  test('should handle missing book gracefully', async () => {
    await page.goto('/book/non-existent-book');
    
    await expect(page.locator('text=Book not found')).toBeVisible();
  });

  test('should handle manifest loading errors', async () => {
    await page.evaluate(() => {
      // @ts-ignore
      window.loadManifest = () => Promise.reject(new Error('Manifest not found'));
    });
    
    await page.goto('/book/test-book-1');
    
    // Should still display basic book info even if manifest fails
    await bookDetailsPage.expectBookTitle('Test Book Title');
  });
});