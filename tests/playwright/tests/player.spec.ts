import { test, expect } from '@playwright/test';
import { PlayerPage } from './pages/player-page';
import { mockApiResponses, testManifest } from './fixtures/test-data';

test.describe('Player', () => {
  let playerPage: PlayerPage;

  test.beforeEach(async ({ page }) => {
    playerPage = new PlayerPage(page);
    
    // Mock native bridge calls
    await page.evaluate(() => {
      // @ts-ignore
      window.loadManifest = () => Promise.resolve(testManifest);
      // @ts-ignore
      window.synthesize = () => Promise.resolve(new Array(1000).fill(0).map((_, i) => i % 256));
      // @ts-ignore
      window.prebuffer = () => Promise.resolve([
        new Array(1000).fill(0).map((_, i) => i % 256),
        new Array(1000).fill(0).map((_, i) => (i + 100) % 256),
        new Array(1000).fill(0).map((_, i) => (i + 200) % 256),
      ]);
      // @ts-ignore
      window.updateLastPosition = () => Promise.resolve();
      // @ts-ignore
      window.getLastPosition = () => Promise.resolve(null);
    });

    await page.goto('/player/test-book-1');
    await playerPage.waitForLoad();
  });

  test('should load book and display initial state', async () => {
    await expect(page.locator('[data-testid="player-view"]')).toBeVisible();
    await playerPage.expectStopped();
  });

  test('should play audio when play button is clicked', async () => {
    await playerPage.play();
    await playerPage.expectPlaying();
  });

  test('should pause audio when pause button is clicked', async () => {
    await playerPage.play();
    await playerPage.expectPlaying();
    
    await playerPage.pause();
    await playerPage.expectPaused();
  });

  test('should resume audio after pause', async () => {
    await playerPage.play();
    await playerPage.pause();
    await playerPage.expectPaused();
    
    await playerPage.play(); // This should resume
    await playerPage.expectPlaying();
  });

  test('should stop audio when stop button is clicked', async () => {
    await playerPage.play();
    await playerPage.expectPlaying();
    
    await playerPage.stop();
    await playerPage.expectStopped();
  });

  test('should navigate to next paragraph', async () => {
    await playerPage.play();
    
    const initialParagraphText = await playerPage.currentParagraph.textContent();
    
    await playerPage.nextParagraph();
    await playerPage.waitForParagraphChange();
    
    const newParagraphText = await playerPage.currentParagraph.textContent();
    expect(newParagraphText).not.toBe(initialParagraphText);
  });

  test('should navigate to previous paragraph', async () => {
    await playerPage.play();
    
    // Go to next paragraph first
    await playerPage.nextParagraph();
    await playerPage.waitForParagraphChange();
    
    const nextParagraphText = await playerPage.currentParagraph.textContent();
    
    // Go back to previous
    await playerPage.previousParagraph();
    await playerPage.waitForParagraphChange();
    
    const previousParagraphText = await playerPage.currentParagraph.textContent();
    expect(previousParagraphText).not.toBe(nextParagraphText);
  });

  test('should seek back 10 seconds', async () => {
    await playerPage.play();
    
    // Wait a bit to have some position
    await page.waitForTimeout(2000);
    
    const initialPosition = await page.locator('[data-testid="position-text"]').textContent();
    
    await playerPage.seekBack();
    
    const newPosition = await page.locator('[data-testid="position-text"]').textContent();
    expect(newPosition).not.toBe(initialPosition);
  });

  test('should change playback speed', async () => {
    await playerPage.setSpeed('1.5');
    await playerPage.expectSpeed('1.5');
    
    await playerPage.setSpeed('2.0');
    await playerPage.expectSpeed('2.0');
  });

  test('should open voice settings dialog', async () => {
    await playerPage.openVoiceSettings();
    
    await expect(page.locator('[data-testid="voice-selector"]')).toBeVisible();
  });

  test('should update progress bar during playback', async () => {
    await playerPage.play();
    
    // Wait a bit for progress to update
    await page.waitForTimeout(1000);
    
    const progressBar = page.locator('[data-testid="progress-bar"] input');
    const progressValue = await progressBar.getAttribute('aria-valuenow');
    expect(parseFloat(progressValue || '0')).toBeGreaterThan(0);
  });

  test('should auto-advance to next paragraph when current finishes', async () => {
    // Mock short audio duration for faster test
    await page.evaluate(() => {
      // @ts-ignore
      window.synthesize = () => Promise.resolve(new Array(100).fill(0)); // Very short audio
    });
    
    await playerPage.play();
    
    const initialParagraphText = await playerPage.currentParagraph.textContent();
    
    // Wait for audio to finish and auto-advance
    await page.waitForTimeout(2000);
    
    const newParagraphText = await playerPage.currentParagraph.textContent();
    expect(newParagraphText).not.toBe(initialParagraphText);
  });

  test('should save playback position', async () => {
    await playerPage.play();
    
    // Play for a bit
    await page.waitForTimeout(1000);
    
    // Mock position save
    let savedPosition: any = null;
    await page.evaluate(() => {
      // @ts-ignore
      window.updateLastPosition = (path, position) => {
        savedPosition = position;
        return Promise.resolve();
      };
    });
    
    await playerPage.goBack();
    
    // Position should have been saved
    expect(savedPosition).toBeTruthy();
  });

  test('should handle loading errors gracefully', async () => {
    await page.evaluate(() => {
      // @ts-ignore
      window.loadManifest = () => Promise.reject(new Error('Failed to load manifest'));
    });
    
    await page.goto('/player/non-existent-book');
    
    await expect(page.locator('text=Error loading book')).toBeVisible();
    await expect(page.locator('[data-testid="retry-button"]')).toBeVisible();
  });

  test('should retry loading when retry button is clicked', async () => {
    // First, simulate an error
    await page.evaluate(() => {
      // @ts-ignore
      window.loadManifest = () => Promise.reject(new Error('Initial error'));
    });
    
    await page.goto('/player/test-book-1');
    await expect(page.locator('text=Error loading book')).toBeVisible();
    
    // Then fix the error and retry
    await page.evaluate(() => {
      // @ts-ignore
      window.loadManifest = () => Promise.resolve(testManifest);
    });
    
    await page.click('[data-testid="retry-button"]');
    
    await playerPage.waitForLoad();
    await playerPage.expectStopped();
  });

  test('should display chapter and paragraph information', async () => {
    await expect(playerPage.chapterInfo).toBeVisible();
    await expect(playerPage.chapterInfo).toContainText('Chapter 1');
    await expect(playerPage.chapterInfo).toContainText('Paragraph 1');
  });
});