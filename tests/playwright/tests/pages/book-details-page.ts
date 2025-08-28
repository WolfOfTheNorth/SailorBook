import { Page, Locator, expect } from '@playwright/test';

export class BookDetailsPage {
  readonly page: Page;
  readonly bookTitle: Locator;
  readonly bookAuthor: Locator;
  readonly bookCover: Locator;
  readonly downloadButton: Locator;
  readonly listenButton: Locator;
  readonly readButton: Locator;
  readonly chaptersList: Locator;
  readonly backButton: Locator;
  readonly bookStats: Locator;

  constructor(page: Page) {
    this.page = page;
    this.bookTitle = page.locator('[data-testid="book-title"]');
    this.bookAuthor = page.locator('[data-testid="book-author"]');
    this.bookCover = page.locator('[data-testid="book-cover"]');
    this.downloadButton = page.locator('[data-testid="download-button"]');
    this.listenButton = page.locator('[data-testid="listen-button"]');
    this.readButton = page.locator('[data-testid="read-button"]');
    this.chaptersList = page.locator('[data-testid="chapters-list"]');
    this.backButton = page.locator('[data-testid="back-button"]');
    this.bookStats = page.locator('[data-testid="book-stats"]');
  }

  async waitForLoad() {
    await this.page.waitForSelector('[data-testid="book-details-view"]', { 
      state: 'visible' 
    });
  }

  async downloadBook() {
    await this.downloadButton.click();
    
    // Wait for download to complete
    await this.page.waitForSelector('[data-testid="download-progress"]', {
      state: 'hidden',
      timeout: 30000
    });
  }

  async startListening() {
    await this.listenButton.click();
  }

  async startReading() {
    await this.readButton.click();
  }

  async playChapter(chapterIndex: number) {
    const chapterPlayButton = this.chaptersList
      .locator(`[data-testid="chapter-${chapterIndex}"] [data-testid="play-button"]`);
    await chapterPlayButton.click();
  }

  async goBack() {
    await this.backButton.click();
  }

  async expectBookTitle(title: string) {
    await expect(this.bookTitle).toContainText(title);
  }

  async expectBookAuthor(author: string) {
    await expect(this.bookAuthor).toContainText(author);
  }

  async expectDownloadButton() {
    await expect(this.downloadButton).toBeVisible();
  }

  async expectListenButton() {
    await expect(this.listenButton).toBeVisible();
  }

  async expectReadButton() {
    await expect(this.readButton).toBeVisible();
  }

  async expectChapters(minCount: number = 1) {
    const chapters = this.chaptersList.locator('[data-testid^="chapter-"]');
    await expect(chapters).toHaveCountGreaterThanOrEqual(minCount);
  }

  async expectBookStats() {
    await expect(this.bookStats).toBeVisible();
  }
}