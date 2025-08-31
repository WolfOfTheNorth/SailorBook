import 'package:flutter_test/flutter_test.dart';
import 'package:pdreader/services/book_service.dart';

void main() {
  group('BookService Integration Tests', () {
    late BookService bookService;

    setUp(() {
      bookService = BookService();
    });

    test('should successfully search for books using Open Library API', () async {
      // Test with a well-known book
      final results = await bookService.searchBooks('alice wonderland');
      
      // Verify we got some results
      expect(results, isNotEmpty);
      
      // Verify the first result has proper structure
      final firstBook = results.first;
      expect(firstBook.id, isNotEmpty);
      expect(firstBook.title, isNotEmpty);
      expect(firstBook.author, isNotEmpty);
      expect(firstBook.downloadUrl, isNotEmpty);
      
      // Print results for debugging
      print('📚 Search Results:');
      for (int i = 0; i < results.length && i < 3; i++) {
        final book = results[i];
        print('  ${i + 1}. "${book.title}" by ${book.author}');
        print('     ID: ${book.id}');
        print('     Download: ${book.downloadUrl}');
        if (book.coverUrl != null) {
          print('     Cover: ${book.coverUrl}');
        }
        print('');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('should return empty list for no results', () async {
      // Test with a query that should return no results
      final results = await bookService.searchBooks('xyznotarealbook123456');
      
      // Should return empty list, not throw error
      expect(results, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('should handle empty query', () async {
      final results = await bookService.searchBooks('');
      
      // Should return empty list for empty query
      expect(results, isEmpty);
    });

    test('should filter results to only downloadable books', () async {
      final results = await bookService.searchBooks('shakespeare');
      
      // All results should have download URLs (indicating they passed the 'ia' filter)
      for (final book in results) {
        expect(book.downloadUrl, contains('archive.org'));
        expect(book.downloadUrl, endsWith('.epub'));
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}