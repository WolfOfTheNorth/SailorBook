import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../services/book_service.dart';
import '../services/web_storage_service.dart';
import '../generated/native.dart' as native;

final bookServiceProvider = Provider<BookService>((ref) => BookService());

final libraryControllerProvider = StateNotifierProvider<LibraryController, LibraryState>(
  (ref) => LibraryController(ref.read(bookServiceProvider)),
);

class LibraryState {
  final List<Book> searchResults;
  final List<Book> downloadedBooks;
  final bool isSearching;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final Map<String, double> downloadProgress; // bookId -> progress (0.0 to 1.0)

  const LibraryState({
    this.searchResults = const [],
    this.downloadedBooks = const [],
    this.isSearching = false,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.downloadProgress = const {},
  });

  LibraryState copyWith({
    List<Book>? searchResults,
    List<Book>? downloadedBooks,
    bool? isSearching,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Map<String, double>? downloadProgress,
  }) {
    return LibraryState(
      searchResults: searchResults ?? this.searchResults,
      downloadedBooks: downloadedBooks ?? this.downloadedBooks,
      isSearching: isSearching ?? this.isSearching,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  final BookService _bookService;

  LibraryController(this._bookService) : super(const LibraryState()) {
    loadDownloadedBooks();
  }

  Future<void> searchBooks(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], searchQuery: '');
      return;
    }

    state = state.copyWith(
      isSearching: true,
      error: null,
      searchQuery: query,
    );

    try {
      final results = await _bookService.searchBooks(query);
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString(),
      );
    }
  }

  Future<void> downloadBook(Book book) async {
    debugPrint('🚀 Starting download: ${book.title} (ID: ${book.id})');
    
    // Initialize download progress
    final updatedProgress = Map<String, double>.from(state.downloadProgress);
    updatedProgress[book.id] = 0.0;
    
    state = state.copyWith(
      downloadProgress: updatedProgress,
      error: null,
    );
    
    debugPrint('📊 Download progress initialized for ${book.id}');

    try {
      // Download the EPUB file with progress tracking
      final localPath = await _bookService.downloadBook(
        book,
        onProgress: (progress) {
          // Update progress in real-time
          final currentProgress = Map<String, double>.from(state.downloadProgress);
          currentProgress[book.id] = progress;
          state = state.copyWith(downloadProgress: currentProgress);
        },
      );
      
      // Generate manifest - platform specific
      if (kIsWeb) {
        // For web, manually add the book to our downloaded list
        final updatedBook = book.copyWith(
          isDownloaded: true,
          localPath: localPath,
        );
        
        // Add to current state immediately
        final currentDownloaded = List<Book>.from(state.downloadedBooks);
        currentDownloaded.add(updatedBook);
        
        state = state.copyWith(downloadedBooks: currentDownloaded);
        debugPrint('📋 Web download complete: ${book.title} - Added to library');
      } else {
        // For mobile/desktop, use Rust FFI (mock for now)
        try {
          final manifest = await native.buildManifest(localPath);
          final manifestPath = '${localPath.replaceAll('/book.epub', '')}/manifest.json';
          await native.saveManifest(manifestPath, manifest);
        } catch (e) {
          debugPrint('⚠️ Manifest generation failed (expected in development): $e');
          // Don't fail the download just because manifest generation failed
        }
      }
      
      // Update downloaded books list - platform specific
      if (!kIsWeb) {
        // Only reload from file system on mobile/desktop
        await loadDownloadedBooks();
      }
      
      // Remove from download progress (download complete)
      final finalProgress = Map<String, double>.from(state.downloadProgress);
      finalProgress.remove(book.id);
      
      state = state.copyWith(downloadProgress: finalProgress);
      
      debugPrint('✅ Download completed successfully: ${book.title}');
      debugPrint('📚 Total books in library: ${state.downloadedBooks.length}');
    } catch (e) {
      // Remove failed download from progress tracking
      final finalProgress = Map<String, double>.from(state.downloadProgress);
      finalProgress.remove(book.id);
      
      state = state.copyWith(
        downloadProgress: finalProgress,
        // Don't set global error here - let the UI handle it locally
      );
      
      debugPrint('❌ Download failed: ${book.title} - Error: $e');
      
      // Re-throw so the BookDetailsView can handle it locally
      rethrow;
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await _bookService.deleteBook(bookId);
      await loadDownloadedBooks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadDownloadedBooks() async {
    try {
      final books = await _bookService.getDownloadedBooks();
      state = state.copyWith(downloadedBooks: books);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}