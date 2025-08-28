import { test, expect } from '@playwright/test';
import { LibraryPage } from './pages/library-page';
import { BookDetailsPage } from './pages/book-details-page';
import { PlayerPage } from './pages/player-page';
import { mockApiResponses, testManifest } from './fixtures/test-data';

test.describe('End-to-End User Flows', () => {
  let libraryPage: LibraryPage;
  let bookDetailsPage: BookDetailsPage;
  let playerPage: PlayerPage;

  test.beforeEach(async ({ page }) => {
    libraryPage = new LibraryPage(page);
    bookDetailsPage = new BookDetailsPage(page);
    playerPage = new PlayerPage(page);
    
    // Mock all API responses
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
      // @ts-ignore
      window.synthesize = () => Promise.resolve(new Array(1000).fill(0).map((_, i) => i % 256));
      // @ts-ignore
      window.prebuffer = () => Promise.resolve([
        new Array(1000).fill(0).map((_, i) => i % 256),
        new Array(1000).fill(0).map((_, i) => (i + 100) % 256),
      ]);
      // @ts-ignore
      window.updateLastPosition = () => Promise.resolve();
      // @ts-ignore
      window.getLastPosition = () => Promise.resolve(null);
    });

    await libraryPage.goto();
  });

  test('Complete user journey: Search → Download → Listen', async () => {
    // 1. Start with empty library
    await libraryPage.expectEmptyLibrary();
    
    // 2. Search for a book
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice wonderland');
    await libraryPage.expectSearchResults(1);
    
    // 3. View book details
    await libraryPage.openFirstBook();
    await bookDetailsPage.waitForLoad();
    await bookDetailsPage.expectBookTitle('Alice\'s Adventures in Wonderland');
    await bookDetailsPage.expectDownloadButton();
    
    // 4. Download the book
    await bookDetailsPage.downloadBook();
    await bookDetailsPage.expectListenButton();
    await bookDetailsPage.expectChapters(3);
    
    // 5. Start listening
    await bookDetailsPage.startListening();
    await playerPage.waitForLoad();
    await playerPage.expectStopped();
    
    // 6. Play the book
    await playerPage.play();
    await playerPage.expectPlaying();
    
    // 7. Test navigation controls
    await playerPage.nextParagraph();
    await playerPage.waitForParagraphChange();
    
    // 8. Test speed control
    await playerPage.setSpeed('1.5');
    await playerPage.expectSpeed('1.5');
    
    // 9. Go back to library and verify book is there
    await playerPage.goBack();
    await libraryPage.switchToLibraryTab();
    await libraryPage.expectBooksInLibrary(1);
  });

  test('Resume playback from last position', async () => {
    // Mock existing book with saved position
    let savedPosition = {
      chapterId: 1,
      paragraphId: 5,
      offsetMs: 15000,
    };
    
    await page.evaluate((position) => {
      // @ts-ignore
      window.getLastPosition = () => Promise.resolve(position);
    }, savedPosition);
    
    // Navigate directly to player
    await page.goto('/player/test-book-1');
    await playerPage.waitForLoad();
    
    // Should resume from saved position
    await expect(playerPage.chapterInfo).toContainText('Chapter 2'); // chapterId: 1 = Chapter 2
    await expect(playerPage.chapterInfo).toContainText('Paragraph 6'); // paragraphId: 5 = Paragraph 6
  });

  test('Handle network errors gracefully', async () => {
    // Mock network error for search
    await page.route('**/search.json*', async route => {
      await route.abort();
    });
    
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice');
    
    // Should show error message
    await expect(page.locator('[data-testid="error-message"]')).toBeVisible();
    
    // Retry with working network
    await page.route('**/search.json*', async route => {
      await route.fulfill({
        contentType: 'application/json',
        body: JSON.stringify(mockApiResponses.searchBooks),
      });
    });
    
    await libraryPage.searchForBooks('alice');
    await libraryPage.expectSearchResults(1);
  });

  test('Voice settings persistence', async () => {
    // Go to player and change voice settings
    await page.goto('/player/test-book-1');
    await playerPage.waitForLoad();
    
    await playerPage.openVoiceSettings();
    
    // Change voice to female
    await page.click('[data-testid="voice-en_us_female"]');
    
    // Change speed to 1.25x
    await page.click('[data-testid="speed-1.25"]');
    
    // Apply settings
    await page.click('[data-testid="apply-settings"]');
    
    // Go back and return to player
    await playerPage.goBack();
    await page.goto('/player/test-book-1');
    await playerPage.waitForLoad();
    
    // Settings should be persisted
    await playerPage.expectSpeed('1.25');
    
    await playerPage.openVoiceSettings();
    await expect(page.locator('[data-testid="voice-en_us_female"][data-selected="true"]'))
      .toBeVisible();
  });

  test('Offline functionality after download', async () => {
    // Download a book first
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice');
    await libraryPage.downloadFirstBook();
    
    // Simulate offline mode
    await page.route('**/*', route => route.abort());
    
    // Should still be able to access downloaded book
    await libraryPage.switchToLibraryTab();
    await libraryPage.expectBooksInLibrary(1);
    
    await libraryPage.playFirstBook();
    await playerPage.waitForLoad();
    
    // Should be able to play offline
    await playerPage.play();
    await playerPage.expectPlaying();
  });

  test('Multiple books management', async () => {
    // Search and download first book
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice');
    await libraryPage.downloadFirstBook();
    
    // Search for different book
    await libraryPage.searchForBooks('tom sawyer');
    await libraryPage.expectSearchResults(1);
    
    // Download second book
    await libraryPage.downloadFirstBook();
    
    // Verify both books in library
    await libraryPage.switchToLibraryTab();
    await libraryPage.expectBooksInLibrary(2);
    
    // Should be able to switch between books
    const bookCards = await libraryPage.getSearchResults();
    await bookCards[0].click();
    await bookDetailsPage.waitForLoad();
    await bookDetailsPage.expectBookTitle('Alice\'s Adventures in Wonderland');
    
    await bookDetailsPage.goBack();
    await bookCards[1].click();
    await bookDetailsPage.waitForLoad();
    await bookDetailsPage.expectBookTitle('The Adventures of Tom Sawyer');
  });

  test('Delete book functionality', async () => {
    // Download a book first
    await libraryPage.switchToSearchTab();
    await libraryPage.searchForBooks('alice');
    await libraryPage.downloadFirstBook();
    
    await libraryPage.switchToLibraryTab();
    await libraryPage.expectBooksInLibrary(1);
    
    // Delete the book
    const firstCard = libraryPage.bookCards.first();
    const deleteButton = firstCard.locator('[data-testid="delete-button"]');
    await deleteButton.click();
    
    // Confirm deletion
    await page.click('text=Delete');
    
    // Library should be empty again
    await libraryPage.expectEmptyLibrary();
  });
});