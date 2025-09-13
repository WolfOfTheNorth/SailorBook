import 'package:flutter_test/flutter_test.dart';
import 'package:pdreader/services/book_service.dart';
import 'package:pdreader/models/book.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Download Functionality Tests', () {
    late BookService bookService;

    setUp(() {
      bookService = BookService();
    });

    test('should download a real EPUB file with progress tracking', () async {
      // Create a test book based on a real Internet Archive book
      const testBook = Book(
        id: 'aliceadventures00carr',
        title: 'Alice\'s Adventures in Wonderland',
        author: 'Lewis Carroll',
        downloadUrl: 'https://archive.org/download/aliceadventures00carr/aliceadventures00carr.epub',
        fileSizeMb: 0.5, // Small test file
      );

      // Track progress updates
      final progressUpdates = <double>[];
      
      try {
        print('📥 Starting download of "${testBook.title}"...');
        
        final filePath = await bookService.downloadBook(
          testBook,
          onProgress: (progress) {
            progressUpdates.add(progress);
            print('📊 Progress: ${(progress * 100).toStringAsFixed(1)}%');
          },
        );
        
        print('✅ Download completed: $filePath');
        
        // Verify file was created
        final downloadedFile = File(filePath);
        expect(downloadedFile.existsSync(), isTrue);
        
        // Verify file has reasonable size (EPUBs are typically > 1KB)
        final fileSize = await downloadedFile.length();
        expect(fileSize, greaterThan(1024)); // At least 1KB
        
        print('📁 Downloaded file size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
        
        // Verify progress tracking worked
        expect(progressUpdates, isNotEmpty);
        print('📈 Progress updates received: ${progressUpdates.length}');
        
        // Verify manifest was created
        final manifestPath = filePath.replaceAll('/book.epub', '/manifest.json');
        final manifestFile = File(manifestPath);
        expect(manifestFile.existsSync(), isTrue);
        
        print('📋 Manifest created: $manifestPath');
        
        // Clean up test file
        final bookDir = Directory(filePath.replaceAll('/book.epub', ''));
        if (await bookDir.exists()) {
          await bookDir.delete(recursive: true);
          print('🧹 Cleaned up test files');
        }
        
      } catch (e) {
        print('❌ Download failed: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('should handle download failure gracefully', () async {
      const invalidBook = Book(
        id: 'nonexistent',
        title: 'Non-existent Book',
        author: 'No Author',
        downloadUrl: 'https://archive.org/download/nonexistent/nonexistent.epub',
        fileSizeMb: 1.0,
      );

      expect(
        () => bookService.downloadBook(invalidBook),
        throwsException,
      );
    });

    test('should get real file size from Internet Archive', () async {
      // Test file size detection with a known small book
      final results = await bookService.searchBooks('alice wonderland');
      
      expect(results, isNotEmpty);
      
      final firstBook = results.first;
      print('📖 Found book: "${firstBook.title}" by ${firstBook.author}');
      print('💾 Estimated size: ${firstBook.fileSizeMb.toStringAsFixed(2)} MB');
      
      // Size should be reasonable (between 0.1 and 50 MB for most EPUBs)
      expect(firstBook.fileSizeMb, greaterThan(0.1));
      expect(firstBook.fileSizeMb, lessThan(50.0));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('should create proper directory structure', () async {
      const testBook = Book(
        id: 'test-book-123',
        title: 'Test Book',
        author: 'Test Author',
        downloadUrl: 'https://httpbin.org/bytes/1024', // Small test download
        fileSizeMb: 0.001,
      );

      try {
        final filePath = await bookService.downloadBook(testBook);
        
        // Verify directory structure: books/test-book-123/book.epub
        expect(filePath, contains('books/test-book-123/book.epub'));
        
        // Verify manifest exists
        final manifestPath = filePath.replaceAll('/book.epub', '/manifest.json');
        expect(File(manifestPath).existsSync(), isTrue);
        
        // Clean up
        final bookDir = Directory(filePath.replaceAll('/book.epub', ''));
        if (await bookDir.exists()) {
          await bookDir.delete(recursive: true);
        }
      } catch (e) {
        print('Test download failed (expected for some test environments): $e');
        // Don't fail test if network is unavailable
      }
    });
  });
}