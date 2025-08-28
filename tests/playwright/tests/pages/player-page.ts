import { Page, Locator, expect } from '@playwright/test';

export class PlayerPage {
  readonly page: Page;
  readonly playButton: Locator;
  readonly pauseButton: Locator;
  readonly nextButton: Locator;
  readonly previousButton: Locator;
  readonly seekBackButton: Locator;
  readonly stopButton: Locator;
  readonly progressBar: Locator;
  readonly speedControls: Locator;
  readonly voiceButton: Locator;
  readonly currentParagraph: Locator;
  readonly chapterInfo: Locator;

  constructor(page: Page) {
    this.page = page;
    this.playButton = page.locator('[data-testid="play-button"]');
    this.pauseButton = page.locator('[data-testid="pause-button"]');
    this.nextButton = page.locator('[data-testid="next-button"]');
    this.previousButton = page.locator('[data-testid="previous-button"]');
    this.seekBackButton = page.locator('[data-testid="seek-back-button"]');
    this.stopButton = page.locator('[data-testid="stop-button"]');
    this.progressBar = page.locator('[data-testid="progress-bar"]');
    this.speedControls = page.locator('[data-testid="speed-controls"]');
    this.voiceButton = page.locator('[data-testid="voice-button"]');
    this.currentParagraph = page.locator('[data-testid="current-paragraph"]');
    this.chapterInfo = page.locator('[data-testid="chapter-info"]');
  }

  async waitForLoad() {
    await this.page.waitForSelector('[data-testid="player-view"]', { 
      state: 'visible' 
    });
  }

  async play() {
    await this.playButton.click();
    await this.waitForPlayback();
  }

  async pause() {
    await this.pauseButton.click();
  }

  async stop() {
    await this.stopButton.click();
  }

  async nextParagraph() {
    await this.nextButton.click();
    await this.waitForParagraphChange();
  }

  async previousParagraph() {
    await this.previousButton.click();
    await this.waitForParagraphChange();
  }

  async seekBack() {
    await this.seekBackButton.click();
  }

  async setSpeed(speed: string) {
    const speedChip = this.page.locator(`[data-testid="speed-${speed}"]`);
    await speedChip.click();
  }

  async openVoiceSettings() {
    await this.voiceButton.click();
    await this.page.waitForSelector('[data-testid="voice-selector"]', {
      state: 'visible'
    });
  }

  async waitForPlayback() {
    // Wait for audio to start playing
    await this.page.waitForSelector('[data-testid="playing-state"]', {
      state: 'visible',
      timeout: 10000
    });
  }

  async waitForParagraphChange() {
    // Wait for paragraph content to change
    await this.page.waitForTimeout(1000);
  }

  async expectPlaying() {
    await expect(this.page.locator('[data-testid="playing-state"]')).toBeVisible();
  }

  async expectPaused() {
    await expect(this.page.locator('[data-testid="paused-state"]')).toBeVisible();
  }

  async expectStopped() {
    await expect(this.page.locator('[data-testid="stopped-state"]')).toBeVisible();
  }

  async expectCurrentParagraph(text: string) {
    await expect(this.currentParagraph).toContainText(text);
  }

  async expectSpeed(speed: string) {
    const speedChip = this.page.locator(`[data-testid="speed-${speed}"][data-selected="true"]`);
    await expect(speedChip).toBeVisible();
  }

  async goBack() {
    await this.page.goBack();
  }
}