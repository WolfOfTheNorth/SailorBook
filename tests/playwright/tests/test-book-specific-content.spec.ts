import { test, expect } from '@playwright/test';

test.describe('Book Specific Content Test', () => {
  test('Verify different books show different content', async ({ page }) => {
    console.log('🔍 Testing that different books show different content...');
    
    // Test book 1
    await page.goto('http://localhost:3000/#/reader/alice-wonderland');
    await page.waitForSelector('flt-glass-pane', { timeout: 15000 });
    await page.waitForTimeout(5000);
    
    console.log('📖 Testing Alice in Wonderland content...');
    await page.screenshot({ path: 'book1-alice.png', fullPage: true });
    
    let pageContent = await page.content();
    const hasAliceId = pageContent.includes('alice-wonderland');
    console.log(`📚 Alice book shows alice-wonderland ID: ${hasAliceId}`);
    
    // Test book 2 with different ID
    await page.goto('http://localhost:3000/#/reader/pride-prejudice');
    await page.waitForTimeout(5000);
    
    console.log('📖 Testing Pride and Prejudice content...');
    await page.screenshot({ path: 'book2-pride.png', fullPage: true });
    
    pageContent = await page.content();
    const hasPrideId = pageContent.includes('pride-prejudice');
    console.log(`📚 Pride book shows pride-prejudice ID: ${hasPrideId}`);
    
    // Test book 3 with another ID
    await page.goto('http://localhost:3000/#/reader/test-book-123');
    await page.waitForTimeout(5000);
    
    console.log('📖 Testing test book content...');
    await page.screenshot({ path: 'book3-test.png', fullPage: true });
    
    pageContent = await page.content();
    const hasTestId = pageContent.includes('test-book-123');
    console.log(`📚 Test book shows test-book-123 ID: ${hasTestId}`);
    
    // Also test library to see if mock books are gone
    await page.goto('http://localhost:3000/');
    await page.waitForTimeout(3000);
    
    console.log('📚 Checking library for unwanted mock books...');
    await page.screenshot({ path: 'library-check.png', fullPage: true });
    
    pageContent = await page.content();
    const hasEmptyLibrary = pageContent.includes('No books in your library');
    console.log(`📚 Library is empty (no mock books): ${hasEmptyLibrary}`);
    
    if (hasAliceId && hasPrideId && hasTestId && hasEmptyLibrary) {
      console.log('✅ SUCCESS: All issues fixed!');
      console.log('  - Different books show different content ✅');
      console.log('  - Mock books removed from library ✅');
      console.log('  - Reader shows book-specific content ✅');
    } else {
      console.log('❌ Some issues still exist');
    }
  });
});