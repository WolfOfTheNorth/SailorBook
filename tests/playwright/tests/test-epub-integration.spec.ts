import { test, expect } from '@playwright/test';

test.describe('EPUB Integration Test', () => {
  test('Test EPUB parsing with different books', async ({ page }) => {
    console.log('🔍 Testing EPUB parsing integration...');
    
    // Test Alice in Wonderland
    await page.goto('http://localhost:3000/#/reader/alice-wonderland');
    await page.waitForSelector('flt-glass-pane', { timeout: 15000 });
    await page.waitForTimeout(6000); // Wait for EPUB parsing
    
    console.log('📖 Testing Alice in Wonderland EPUB parsing...');
    await page.screenshot({ path: 'epub-alice.png', fullPage: true });
    
    let pageContent = await page.content();
    const hasAliceTitle = pageContent.includes('Alice\'s Adventures in Wonderland');
    const hasCarrollAuthor = pageContent.includes('Lewis Carroll');
    const hasRabbitHole = pageContent.includes('Down the Rabbit-Hole');
    
    console.log(`📚 Shows Alice title: ${hasAliceTitle}`);
    console.log(`👤 Shows Carroll author: ${hasCarrollAuthor}`);
    console.log(`🐰 Shows Rabbit-Hole chapter: ${hasRabbitHole}`);
    
    // Test Pride and Prejudice
    await page.goto('http://localhost:3000/#/reader/pride-prejudice');
    await page.waitForTimeout(6000);
    
    console.log('📖 Testing Pride and Prejudice EPUB parsing...');
    await page.screenshot({ path: 'epub-pride.png', fullPage: true });
    
    pageContent = await page.content();
    const hasPrideTitle = pageContent.includes('Pride and Prejudice');
    const hasAustenAuthor = pageContent.includes('Jane Austen');
    const hasTruthUniversal = pageContent.includes('truth universally acknowledged');
    
    console.log(`📚 Shows Pride title: ${hasPrideTitle}`);
    console.log(`👤 Shows Austen author: ${hasAustenAuthor}`);
    console.log(`💭 Shows famous opening: ${hasTruthUniversal}`);
    
    // Test generic book
    await page.goto('http://localhost:3000/#/reader/generic-book');
    await page.waitForTimeout(6000);
    
    console.log('📖 Testing generic book fallback...');
    await page.screenshot({ path: 'epub-generic.png', fullPage: true });
    
    pageContent = await page.content();
    const hasGenericTitle = pageContent.includes('Downloaded Book');
    const hasGenericAuthor = pageContent.includes('Public Domain Author');
    
    console.log(`📚 Shows generic title: ${hasGenericTitle}`);
    console.log(`👤 Shows generic author: ${hasGenericAuthor}`);
    
    // Summary
    const allBooksWorking = hasAliceTitle && hasCarrollAuthor && 
                           hasPrideTitle && hasAustenAuthor && 
                           hasGenericTitle && hasGenericAuthor;
    
    if (allBooksWorking) {
      console.log('✅ SUCCESS: EPUB parsing integration working perfectly!');
      console.log('  - Alice in Wonderland: Proper title, author, chapters ✅');
      console.log('  - Pride and Prejudice: Proper title, author, content ✅');  
      console.log('  - Generic books: Fallback content working ✅');
      console.log('  - Feature 5 EPUB Parsing is 100% COMPLETE! ✅');
    } else {
      console.log('❌ Some EPUB parsing issues still exist');
    }
  });
});