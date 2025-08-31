import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Web-specific storage service for handling EPUB downloads and metadata
/// in browser environments where file system access is limited
class WebStorageService {
  static final Map<String, Uint8List> _inMemoryStorage = {};
  static final Map<String, Map<String, dynamic>> _manifests = {};
  
  /// Downloads and stores an EPUB file in web-compatible storage
  static Future<String> downloadBook(
    String bookId, 
    String title,
    Stream<List<int>> dataStream,
    {Function(double)? onProgress, int? contentLength}
  ) async {
    debugPrint('📱 Web Storage: Downloading $title (ID: $bookId)');
    
    final List<int> fileBytes = [];
    int downloadedBytes = 0;
    
    await for (final chunk in dataStream) {
      fileBytes.addAll(chunk);
      downloadedBytes += chunk.length;
      
      if (onProgress != null && contentLength != null && contentLength > 0) {
        final progress = downloadedBytes / contentLength;
        onProgress(progress.clamp(0.0, 1.0));
      }
    }
    
    // Store in memory (in a real implementation, this would use IndexedDB)
    final fileData = Uint8List.fromList(fileBytes);
    _inMemoryStorage[bookId] = fileData;
    
    debugPrint('✅ Web Storage: Downloaded ${fileBytes.length} bytes for $title');
    debugPrint('💾 Stored in memory storage (IndexedDB implementation pending)');
    
    return '/web-storage/books/$bookId/book.epub';
  }
  
  /// Saves book metadata manifest
  static Future<void> saveManifest(String bookId, Map<String, dynamic> manifest) async {
    _manifests[bookId] = Map<String, dynamic>.from(manifest);
    debugPrint('📋 Web Storage: Saved manifest for $bookId');
    debugPrint('📊 Total books in storage: ${_manifests.length}');
  }
  
  /// Gets stored EPUB data
  static Uint8List? getBookData(String bookId) {
    return _inMemoryStorage[bookId];
  }
  
  /// Gets stored manifest
  static Map<String, dynamic>? getManifest(String bookId) {
    return _manifests[bookId];
  }
  
  /// Lists all downloaded books
  static List<Map<String, dynamic>> getAllManifests() {
    return _manifests.values.toList();
  }
  
  /// Deletes a book and its manifest
  static Future<void> deleteBook(String bookId) async {
    _inMemoryStorage.remove(bookId);
    _manifests.remove(bookId);
    debugPrint('🗑️ Web Storage: Deleted $bookId');
  }
  
  /// Clears all stored data
  static void clearAll() {
    _inMemoryStorage.clear();
    _manifests.clear();
    debugPrint('🧹 Web Storage: Cleared all data');
  }
  
  /// Gets storage statistics
  static Map<String, dynamic> getStorageStats() {
    final totalBooks = _inMemoryStorage.length;
    final totalBytes = _inMemoryStorage.values
        .fold<int>(0, (sum, data) => sum + data.length);
    
    return {
      'totalBooks': totalBooks,
      'totalBytes': totalBytes,
      'totalMB': (totalBytes / (1024 * 1024)).toStringAsFixed(2),
    };
  }
}