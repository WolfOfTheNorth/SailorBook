import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';

class BookService {
  static const String _openLibrarySearchUrl = 'https://openlibrary.org/search.json';
  static const String _gutenbergBaseUrl = 'https://www.gutenberg.org';
  
  Future<List<Book>> searchBooks(String query) async {
    try {
      final uri = Uri.parse(_openLibrarySearchUrl).replace(queryParameters: {
        'q': query,
        'limit': '20',
        'fields': 'key,title,author_name,cover_i,first_publish_year,ia',
      });
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List docs = data['docs'] ?? [];
        
        return docs
            .where((doc) => doc['ia'] != null && (doc['ia'] as List).isNotEmpty)
            .map((doc) => _parseOpenLibraryDoc(doc))
            .where((book) => book != null)
            .cast<Book>()
            .toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('Failed to search books: $e');
    }
  }
  
  Book? _parseOpenLibraryDoc(Map<String, dynamic> doc) {
    try {
      final key = doc['key'] as String?;
      final title = doc['title'] as String?;
      final authorNames = doc['author_name'] as List?;
      final coverId = doc['cover_i'] as int?;
      final internetArchiveIds = doc['ia'] as List?;
      
      if (key == null || title == null || internetArchiveIds == null || internetArchiveIds.isEmpty) {
        return null;
      }
      
      final author = authorNames?.first ?? 'Unknown Author';
      final iaId = internetArchiveIds.first as String;
      final bookId = key.split('/').last;
      
      return Book(
        id: bookId,
        title: title,
        author: author,
        coverUrl: coverId != null 
            ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
            : null,
        downloadUrl: 'https://archive.org/download/$iaId/$iaId.epub',
        fileSizeMb: 2.5, // Estimated size
      );
    } catch (e) {
      return null;
    }
  }
  
  Future<String> downloadBook(Book book, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books/${book.id}');
      await booksDir.create(recursive: true);
      
      final filePath = '${booksDir.path}/book.epub';
      
      final response = await http.get(Uri.parse(book.downloadUrl));
      
      if (response.statusCode == 200) {
        await File(filePath).writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download book: $e');
    }
  }
  
  Future<void> deleteBook(String bookId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${appDir.path}/books/$bookId');
      
      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }
  
  Future<List<Book>> getDownloadedBooks() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      
      if (!await booksDir.exists()) {
        return [];
      }
      
      final List<Book> books = [];
      await for (final entity in booksDir.list()) {
        if (entity is Directory) {
          final bookId = entity.path.split('/').last;
          final manifestFile = File('${entity.path}/manifest.json');
          
          if (await manifestFile.exists()) {
            try {
              final manifestContent = await manifestFile.readAsString();
              final manifestData = json.decode(manifestContent);
              
              books.add(Book(
                id: bookId,
                title: manifestData['title'] ?? 'Unknown Title',
                author: manifestData['author'] ?? 'Unknown Author',
                downloadUrl: '',
                fileSizeMb: 0,
                isDownloaded: true,
                localPath: entity.path,
              ));
            } catch (e) {
              // Skip invalid manifest files
            }
          }
        }
      }
      
      return books;
    } catch (e) {
      return [];
    }
  }
}