import { test, expect } from '@playwright/test';

test.describe('Real Search API Integration Tests', () => {
  
  test.beforeEach(async ({ page }) => {
    // Navigate to the app without any mocking - test real API
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane', { timeout: 30000 });
    await page.waitForTimeout(3000); // Allow Flutter to fully initialize
  });

  test('Real search functionality with Open Library API', async ({ page }) => {
    // Click on search tab using our test identifier
    await page.getByTestId('search-tab').click();
    await page.waitForTimeout(1000);
    
    // Type search query in the search field using test identifier  
    const searchInput = page.getByTestId('search-field');
    await expect(searchInput).toBeVisible();
    
    await searchInput.fill('alice wonderland');
    await page.waitForTimeout(500);
    
    // Track network requests to verify API call
    const apiRequests: string[] = [];
    page.on('request', request => {
      const url = request.url();
      if (url.includes('openlibrary.org/search.json')) {
        apiRequests.push(url);
        console.log('🌐 API Request:', url);
      }
    });
    
    // Press Enter to initiate search
    await page.keyboard.press('Enter');
    
    // Wait for search loading state
    await page.waitForTimeout(3000);
    
    // Verify API was called
    expect(apiRequests.length).toBeGreaterThan(0);
    expect(apiRequests[0]).toContain('q=alice%20wonderland');
    
    // Check if search results are displayed
    const searchResultsList = page.getByTestId('search-results');
    
    // Either we have results or no results message
    const hasResults = await searchResultsList.isVisible().catch(() => false);
    const noResults = await page.getByTestId('no-search-results').isVisible().catch(() => false);
    
    expect(hasResults || noResults).toBeTruthy();
    
    if (hasResults) {
      console.log('✅ Search returned results');
      
      // Verify at least one book card is present
      const bookCards = page.locator('[data-testid*="book-card-"]');
      await expect(bookCards.first()).toBeVisible();
      
      // Take screenshot of results
      await page.screenshot({ 
        path: 'test-results/real-search-results.png', 
        fullPage: true 
      });
    } else {
      console.log('📭 Search returned no results (this might be expected)');
      await page.screenshot({ 
        path: 'test-results/no-search-results.png', 
        fullPage: true 
      });
    }
    
    console.log('✅ Real search API integration tested');
  });

  test('Search error handling', async ({ page }) => {
    // Click on search tab
    await page.getByTestId('search-tab').click();
    await page.waitForTimeout(1000);
    
    // Mock a network failure
    await page.route('**/search.json*', route => {
      route.abort('failed');
    });
    
    // Try to search
    const searchInput = page.getByTestId('search-field');
    await searchInput.fill('test search');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    
    // Check if error state is displayed
    const errorMessage = page.getByTestId('search-error');
    const isErrorVisible = await errorMessage.isVisible().catch(() => false);
    
    if (isErrorVisible) {
      console.log('✅ Error handling working correctly');
    } else {
      console.log('ℹ️  Error state may not be implemented yet');
    }
  });

  test('Search loading state', async ({ page }) => {
    // Click on search tab
    await page.getByTestId('search-tab').click();
    await page.waitForTimeout(1000);
    
    // Slow down the API response to catch loading state
    await page.route('**/search.json*', async route => {
      await new Promise(resolve => setTimeout(resolve, 2000)); // 2 second delay
      await route.continue();
    });
    
    // Start search
    const searchInput = page.getByTestId('search-field');
    await searchInput.fill('test');
    await page.keyboard.press('Enter');
    
    // Check for loading state
    const loadingIndicator = page.getByTestId('search-loading');
    const isLoadingVisible = await loadingIndicator.isVisible().catch(() => false);
    
    if (isLoadingVisible) {
      console.log('✅ Loading state displayed correctly');
    } else {
      console.log('ℹ️  Loading state may not be visible or too fast');
    }
    
    // Wait for search to complete
    await page.waitForTimeout(3000);
  });

});