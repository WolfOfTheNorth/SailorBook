import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import 'web_storage_service.dart';
import 'simple_web_download.dart';

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
        fileSizeMb: 2.5, // Default estimate - will be updated during download
      );
    } catch (e) {
      return null;
    }
  }
  
  Future<String> downloadBook(Book book, {
    Function(double progress)? onProgress,
  }) async {
    try {
      if (kIsWeb) {
        // Use browser-native download for web to bypass CORS restrictions
        return await _downloadBookWeb(book, onProgress);
      } else {
        // Use direct HTTP download for mobile/desktop
        return await _downloadBookNative(book, onProgress);
      }
    } catch (e) {
      throw Exception(_formatDownloadError(e));
    }
  }

  /// Web-specific download using browser's native download capabilities
  Future<String> _downloadBookWeb(Book book, Function(double)? onProgress) async {
    debugPrint('🌐 BookService: Starting web download for ${book.title}');
    
    // Check if browser download is supported
    if (!SimpleWebDownload.isSupported()) {
      throw Exception('Your browser does not support file downloads. Please use a modern browser.');
    }
    
    try {
      // Create clean filename
      final filename = SimpleWebDownload.createFilename(book.title, book.author);
      
      // Trigger browser download directly (completely bypasses CORS)
      final downloadPath = await SimpleWebDownload.downloadFile(book.downloadUrl, filename);
      
      // Simulate progress for UI feedback
      if (onProgress != null) {
        for (double progress = 0.2; progress <= 1.0; progress += 0.25) {
          await Future.delayed(const Duration(milliseconds: 500));
          onProgress(progress);
        }
      }
      
      // Save book metadata for library tracking
      final booksPath = '/web-storage/books/${book.id}';
      await _saveBookManifest(booksPath, book);
      
      debugPrint('✅ BookService: Browser download initiated successfully');
      return downloadPath;
      
    } catch (e) {
      debugPrint('❌ BookService: Web download failed - $e');
      
      // Provide helpful guidance instead of error
      final guidance = SimpleWebDownload.getUserGuidance();
      throw Exception(guidance);
    }
  }

  /// Native download for mobile/desktop platforms
  Future<String> _downloadBookNative(Book book, Function(double)? onProgress) async {
    final String booksPath;
    final String filePath;
    
    // For mobile/desktop, use normal file system
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${appDir.path}/books/${book.id}');
    await booksDir.create(recursive: true);
    
    booksPath = booksDir.path;
    filePath = '${booksDir.path}/book.epub';
    
    // Use streaming download for progress tracking
    final request = http.Request('GET', Uri.parse(book.downloadUrl));
    
    // Add headers for proper content negotiation
    request.headers.addAll({
      'Accept': 'application/epub+zip, application/octet-stream, */*',
      'User-Agent': 'SailorBook/1.0 (Public Domain Reader)',
      'Cache-Control': 'no-cache',
    });
    
    debugPrint('📥 Downloading from: ${book.downloadUrl}');
    final response = await request.send();
    
    // If the primary URL fails, try alternative URL patterns
    if (response.statusCode != 200) {
      debugPrint('⚠️ Primary download failed (${response.statusCode}), trying alternative URL...');
      return await _tryAlternativeDownload(book, onProgress);
    }
    
    final contentLength = response.contentLength ?? 0;
    int downloadedBytes = 0;
    
    // Update book size estimate if we get actual content length
    if (contentLength > 0) {
      book = book.copyWith(fileSizeMb: contentLength / (1024 * 1024));
    }
    
    // Mobile/desktop file system storage
    final file = File(filePath);
    final fileSink = file.openWrite();
    
    try {
      await for (final chunk in response.stream) {
        fileSink.add(chunk);
        downloadedBytes += chunk.length;
        
        // Report progress if callback provided and we know content length
        if (onProgress != null && contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          onProgress(progress.clamp(0.0, 1.0));
        }
      }
      
      await fileSink.flush();
      await fileSink.close();
      
      // Save book metadata manifest
      await _saveBookManifest(booksPath, book);
      
      return filePath;
    } catch (e) {
      await fileSink.close();
      // Clean up partial download
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  /// Formats download errors with user-friendly messages
  String _formatDownloadError(dynamic error) {
    if (error.toString().contains('Failed to fetch') || 
        error.toString().contains('ClientException') ||
        error.toString().contains('CORS')) {
      
      if (kIsWeb) {
        return SimpleWebDownload.getUserGuidance();
      } else {
        return 'Network connection failed. Please check your internet connection and try again.';
      }
    } else if (error.toString().contains('FormatException')) {
      return 'Invalid download URL format. The book link may be corrupted.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Download timeout. The book file may be too large or the connection is slow.';
    } else {
      return error.toString().replaceAll('Exception: ', '');
    }
  }
  

  Future<void> _saveBookManifest(String bookDir, Book book) async {
    final manifest = {
      'id': book.id,
      'title': book.title,
      'author': book.author,
      'downloadUrl': book.downloadUrl,
      'coverUrl': book.coverUrl,
      'fileSizeMb': book.fileSizeMb,
      'downloadedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
    
    if (kIsWeb) {
      // Use web storage service for manifest
      await WebStorageService.saveManifest(book.id, manifest);
    } else {
      // Mobile/desktop file system storage
      final manifestPath = '$bookDir/manifest.json';
      await File(manifestPath).writeAsString(
        const JsonEncoder.withIndent('  ').convert(manifest),
      );
    }
  }
  
  Future<void> deleteBook(String bookId) async {
    try {
      if (kIsWeb) {
        // Use web storage service for deletion
        await WebStorageService.deleteBook(bookId);
      } else {
        // Mobile/desktop file system storage
        final appDir = await getApplicationDocumentsDirectory();
        final bookDir = Directory('${appDir.path}/books/$bookId');
        
        if (await bookDir.exists()) {
          await bookDir.delete(recursive: true);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  /// Tries alternative download URLs when the primary fails
  Future<String> _tryAlternativeDownload(Book book, Function(double)? onProgress) async {
    final iaId = book.downloadUrl.split('/').reversed.elementAt(1); // Extract IA ID
    
    // Try common alternative patterns for Internet Archive EPUBs
    final alternativeUrls = [
      'https://archive.org/download/$iaId/${iaId}_djvu.epub',
      'https://archive.org/download/$iaId/${iaId}_text.epub', 
      'https://archive.org/download/$iaId/book.epub',
      'https://archive.org/download/$iaId/${iaId}.pdf.epub',
    ];
    
    for (final url in alternativeUrls) {
      try {
        debugPrint('🔄 Trying alternative URL: $url');
        
        final request = http.Request('GET', Uri.parse(url));
        request.headers.addAll({
          'Accept': 'application/epub+zip, application/octet-stream, */*',
          'User-Agent': 'SailorBook/1.0 (Public Domain Reader)',
        });
        
        final response = await request.send();
        
        if (response.statusCode == 200) {
          debugPrint('✅ Alternative URL worked: $url');
          
          // Update the book with working URL
          final updatedBook = book.copyWith(downloadUrl: url);
          
          // Use the working URL to download (avoid infinite recursion)
          final newRequest = http.Request('GET', Uri.parse(url));
          newRequest.headers.addAll({
            'Accept': 'application/epub+zip, application/octet-stream, */*',
            'User-Agent': 'SailorBook/1.0 (Public Domain Reader)',
          });
          
          final newResponse = await newRequest.send();
          return await _processDownloadResponse(updatedBook, newResponse, onProgress);
        }
      } catch (e) {
        debugPrint('❌ Alternative URL failed: $url - $e');
        continue;
      }
    }
    
    throw Exception('All download URLs failed. The book may not be available in EPUB format.');
  }

  /// Processes the download response stream for both primary and alternative downloads
  Future<String> _processDownloadResponse(Book book, http.StreamedResponse response, Function(double)? onProgress) async {
    final contentLength = response.contentLength ?? 0;
    int downloadedBytes = 0;
    
    final String booksPath;
    final String filePath;
    
    if (kIsWeb) {
      booksPath = '/web-storage/books/${book.id}';
      filePath = '$booksPath/book.epub';
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books/${book.id}');
      await booksDir.create(recursive: true);
      booksPath = booksDir.path;
      filePath = '${booksDir.path}/book.epub';
    }
    
    if (kIsWeb) {
      final downloadedPath = await WebStorageService.downloadBook(
        book.id,
        book.title,
        response.stream,
        onProgress: onProgress,
        contentLength: contentLength,
      );
      
      await _saveBookManifest(booksPath, book);
      return downloadedPath;
    } else {
      final file = File(filePath);
      final fileSink = file.openWrite();
      
      try {
        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          downloadedBytes += chunk.length;
          
          if (onProgress != null && contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            onProgress(progress.clamp(0.0, 1.0));
          }
        }
        
        await fileSink.flush();
        await fileSink.close();
        
        await _saveBookManifest(booksPath, book);
        return filePath;
      } catch (e) {
        await fileSink.close();
        if (await file.exists()) {
          await file.delete();
        }
        rethrow;
      }
    }
  }
  
  Future<List<Book>> getDownloadedBooks() async {
    try {
      if (kIsWeb) {
        // Use web storage service to get downloaded books
        final manifests = WebStorageService.getAllManifests();
        return manifests.map((manifest) => Book(
          id: manifest['id'] ?? '',
          title: manifest['title'] ?? 'Unknown Title',
          author: manifest['author'] ?? 'Unknown Author',
          downloadUrl: '',
          fileSizeMb: (manifest['fileSizeMb'] as num?)?.toDouble() ?? 0.0,
          isDownloaded: true,
          localPath: '/web-storage/books/${manifest['id']}',
        )).toList();
      } else {
        // Mobile/desktop file system storage
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
      }
    } catch (e) {
      return [];
    }
  }
}