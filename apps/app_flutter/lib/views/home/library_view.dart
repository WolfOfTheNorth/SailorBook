import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/library_controller.dart';
import '../../widgets/book_card.dart';
import '../../widgets/search_bar.dart';

class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key});

  @override
  ConsumerState<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<LibraryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryControllerProvider);
    final libraryController = ref.read(libraryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public-Domain Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Library'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLibraryTab(libraryState, libraryController),
          _buildSearchTab(libraryState, libraryController),
        ],
      ),
    );
  }

  Widget _buildLibraryTab(LibraryState state, LibraryController controller) {
    if (state.downloadedBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books,
              size: 64.sp,
              color: Theme.of(context).colorScheme.secondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'No books in your library',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              'Search and download books to get started',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Browse Books'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadDownloadedBooks(),
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: state.downloadedBooks.length,
        itemBuilder: (context, index) {
          final book = state.downloadedBooks[index];
          return BookCard(
            book: book,
            isDownloaded: true,
            onTap: () => context.push('/book/${book.id}'),
            onPlay: () => context.push('/player/${book.id}'),
            onDelete: () => _showDeleteDialog(book.id, controller),
          );
        },
      ),
    );
  }

  Widget _buildSearchTab(LibraryState state, LibraryController controller) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.w),
          child: CustomSearchBar(
            controller: _searchController,
            onSearch: controller.searchBooks,
            isLoading: state.isSearching,
          ),
        ),
        if (state.error != null) ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: controller.clearError,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
        Expanded(
          child: _buildSearchResults(state, controller),
        ),
      ],
    );
  }

  Widget _buildSearchResults(LibraryState state, LibraryController controller) {
    if (state.searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64.sp,
              color: Theme.of(context).colorScheme.secondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'Search for public domain books',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              'Find classic literature, historical texts, and more',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: Theme.of(context).colorScheme.secondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'No books found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: state.searchResults.length,
      itemBuilder: (context, index) {
        final book = state.searchResults[index];
        final isDownloaded = state.downloadedBooks
            .any((downloadedBook) => downloadedBook.id == book.id);

        return BookCard(
          book: book,
          isDownloaded: isDownloaded,
          onTap: () => context.push('/book/${book.id}'),
          onDownload: state.isLoading ? null : () => controller.downloadBook(book),
          isDownloading: state.isLoading,
        );
      },
    );
  }

  void _showDeleteDialog(String bookId, LibraryController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text(
          'Are you sure you want to delete this book? '
          'This will remove the book file and all cached audio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteBook(bookId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}