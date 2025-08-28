import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../services/book_service.dart';
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

  const LibraryState({
    this.searchResults = const [],
    this.downloadedBooks = const [],
    this.isSearching = false,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  LibraryState copyWith({
    List<Book>? searchResults,
    List<Book>? downloadedBooks,
    bool? isSearching,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return LibraryState(
      searchResults: searchResults ?? this.searchResults,
      downloadedBooks: downloadedBooks ?? this.downloadedBooks,
      isSearching: isSearching ?? this.isSearching,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
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
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Download the EPUB file
      final localPath = await _bookService.downloadBook(book);
      
      // Generate manifest using Rust
      final manifest = await native.buildManifest(localPath);
      
      // Save manifest
      final manifestPath = '${localPath.replaceAll('/book.epub', '')}/manifest.json';
      await native.saveManifest(manifestPath, manifest);
      
      // Update downloaded books list
      await loadDownloadedBooks();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
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