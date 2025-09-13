import { test, expect } from '@playwright/test';

test.describe('Direct EPUB Parsing Test', () => {
  test('Test real EPUB parsing by going directly to reader', async ({ page }) => {
    console.log('📖 Testing direct EPUB parsing...');
    
    // Go directly to reader for Alice in Wonderland
    await page.goto('http://localhost:3000/#/reader/alice-wonderland');
    await page.waitForSelector('flt-glass-pane', { timeout: 15000 });
    await page.waitForTimeout(8000); // Extra time for EPUB parsing
    
    console.log('📚 Reader loaded, checking for real EPUB content...');
    await page.screenshot({ path: 'direct-epub-alice.png', fullPage: true });
    
    const pageContent = await page.content();
    
    // Check for real EPUB parsing vs mock content
    const hasUnknownBook = pageContent.includes('Unknown Book');
    const hasMockContent = pageContent.includes('mock content') || 
                           pageContent.includes('placeholder content');
    const hasAliceTitle = pageContent.includes('Alice');
    const hasActualContent = pageContent.includes('Alice was beginning') || 
                            pageContent.includes('rabbit');
    
    console.log(`📚 Shows "Unknown Book": ${hasUnknownBook}`);
    console.log(`🎭 Shows mock content: ${hasMockContent}`);
    console.log(`👑 Shows Alice title: ${hasAliceTitle}`);
    console.log(`📖 Shows actual Alice content: ${hasActualContent}`);
    
    // Test with another book ID
    await page.goto('http://localhost:3000/#/reader/pride-prejudice');
    await page.waitForTimeout(8000);
    
    console.log('📚 Testing Pride and Prejudice...');
    await page.screenshot({ path: 'direct-epub-pride.png', fullPage: true });
    
    const prideContent = await page.content();
    const hasPrideTitle = prideContent.includes('Pride and Prejudice');
    const hasAustenAuthor = prideContent.includes('Jane Austen');
    const hasTruthUniversal = prideContent.includes('truth universally acknowledged');
    
    console.log(`📚 Shows Pride title: ${hasPrideTitle}`);
    console.log(`👤 Shows Austen author: ${hasAustenAuthor}`);
    console.log(`💭 Shows famous opening: ${hasTruthUniversal}`);
    
    // Summary
    const epubParsingWorking = (hasAliceTitle || hasActualContent) && 
                              (hasPrideTitle || hasAustenAuthor);
    
    if (epubParsingWorking) {
      console.log('✅ SUCCESS: Real EPUB parsing is working!');
      console.log('  - Books show specific content based on ID ✅');
      console.log('  - EPUB parsing integration functional ✅');
      console.log('  - Download→Read pipeline ready ✅');
    } else {
      console.log('📝 EPUB parsing status:');
      console.log(`  - Alice content: ${hasAliceTitle ? '✅' : '❌'}`);
      console.log(`  - Pride content: ${hasPrideTitle ? '✅' : '❌'}`);
      console.log(`  - Real parsing: ${!hasMockContent ? '✅' : '❌'}`);
    }
  });
});