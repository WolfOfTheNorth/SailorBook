import { Page, Locator, expect } from '@playwright/test';

export class LibraryPage {
  readonly page: Page;
  readonly searchInput: Locator;
  readonly searchTab: Locator;
  readonly libraryTab: Locator;
  readonly bookCards: Locator;
  readonly emptyLibraryMessage: Locator;
  readonly settingsButton: Locator;

  constructor(page: Page) {
    this.page = page;
    this.searchInput = page.locator('[data-testid="search-input"]');
    this.searchTab = page.locator('text=Search');
    this.libraryTab = page.locator('text=Library');
    this.bookCards = page.locator('[data-testid="book-card"]');
    this.emptyLibraryMessage = page.locator('text=No books in your library');
    this.settingsButton = page.locator('[data-testid="settings-button"]');
  }

  async goto() {
    await this.page.goto('/');
    await this.waitForLoad();
  }

  async waitForLoad() {
    await this.page.waitForSelector('[data-testid="library-view"]', { 
      state: 'visible' 
    });
  }

  async searchForBooks(query: string) {
    await this.searchTab.click();
    await this.searchInput.fill(query);
    await this.searchInput.press('Enter');
    
    // Wait for search results or empty state
    await this.page.waitForTimeout(1000);
  }

  async getSearchResults() {
    return await this.bookCards.all();
  }

  async downloadFirstBook() {
    const firstBookCard = this.bookCards.first();
    const downloadButton = firstBookCard.locator('[data-testid="download-button"]');
    await downloadButton.click();
    
    // Wait for download to complete
    await this.page.waitForSelector('[data-testid="download-progress"]', {
      state: 'hidden',
      timeout: 30000
    });
  }

  async openFirstBook() {
    const firstBookCard = this.bookCards.first();
    await firstBookCard.click();
  }

  async playFirstBook() {
    const firstBookCard = this.bookCards.first();
    const playButton = firstBookCard.locator('[data-testid="play-button"]');
    await playButton.click();
  }

  async goToSettings() {
    await this.settingsButton.click();
  }

  async switchToLibraryTab() {
    await this.libraryTab.click();
  }

  async switchToSearchTab() {
    await this.searchTab.click();
  }

  async expectEmptyLibrary() {
    await expect(this.emptyLibraryMessage).toBeVisible();
  }

  async expectBooksInLibrary(count: number) {
    await expect(this.bookCards).toHaveCount(count);
  }

  async expectSearchResults(minCount: number = 1) {
    await expect(this.bookCards).toHaveCountGreaterThanOrEqual(minCount);
  }
}