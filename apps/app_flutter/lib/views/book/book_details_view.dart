import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../models/book.dart';
import '../../utils/test_helpers.dart';
import '../../generated/native.dart' as native;

class BookDetailsView extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailsView({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<BookDetailsView> createState() => _BookDetailsViewState();
}

class _BookDetailsViewState extends ConsumerState<BookDetailsView> {
  BookManifest? _manifest;
  bool _isLoadingManifest = false;
  bool _isDownloading = false;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  Future<void> _loadManifest() async {
    setState(() => _isLoadingManifest = true);
    
    try {
      // For now, we'll mock the manifest path
      final manifestPath = '/data/books/${widget.bookId}/manifest.json';
      final manifest = await native.loadManifest(manifestPath);
      
      if (manifest != null) {
        _manifest = BookManifest(
          bookId: manifest.bookId,
          title: manifest.title,
          author: manifest.author,
          chapters: manifest.chapters.map((c) => Chapter(
            id: c.id,
            title: c.title,
            paragraphIds: c.paragraphIds,
          )).toList(),
          paragraphs: manifest.paragraphs.map((p) => Paragraph(
            id: p.id,
            chapterId: p.chapterId,
            text: p.text,
            wordCount: p.wordCount,
          )).toList(),
          lastPosition: manifest.lastPosition != null
              ? PlaybackPosition(
                  chapterId: manifest.lastPosition!.chapterId,
                  paragraphId: manifest.lastPosition!.paragraphId,
                  offsetMs: manifest.lastPosition!.offsetMs,
                )
              : null,
        );
      }
    } catch (e) {
      debugPrint('Error loading manifest: $e');
    }
    
    setState(() => _isLoadingManifest = false);
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryControllerProvider);
    final book = _findBook(libraryState);

    return Scaffold(
      appBar: AppBar(
        title: Text(book?.title ?? 'Book Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: book == null
          ? const Center(child: Text('Book not found')).withTestId('book-not-found', label: 'Book Not Found')
          : _isLoadingManifest
              ? const Center(child: CircularProgressIndicator()).withTestId('manifest-loading', label: 'Loading Book Details')
              : _buildBookDetails(book),
    );
  }

  Book? _findBook(LibraryState state) {
    return state.downloadedBooks
        .where((book) => book.id == widget.bookId)
        .firstOrNull ??
        state.searchResults
            .where((book) => book.id == widget.bookId)
            .firstOrNull;
  }

  Widget _buildBookDetails(Book book) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookHeader(book),
          SizedBox(height: 24.h),
          if (_downloadError != null) ...[
            _isSuccessMessage(_downloadError!) ? _buildSuccessCard() : _buildErrorCard(),
            SizedBox(height: 16.h),
          ],
          _buildActionButtons(book),
          if (_manifest != null) ...[
            SizedBox(height: 32.h),
            _buildChaptersList(),
          ],
        ],
      ),
    );
  }

  Widget _buildBookHeader(Book book) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Container(
              width: 100.w,
              height: 150.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: book.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderCover(),
                      ),
                    )
                  : _buildPlaceholderCover(),
            ),
            SizedBox(width: 16.w),
            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'by ${book.author}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  SizedBox(height: 16.h),
                  if (_manifest != null) ...[
                    _buildBookStat(
                      'Chapters',
                      '${_manifest!.chapters.length}',
                      Icons.menu_book,
                    ),
                    SizedBox(height: 8.h),
                    _buildBookStat(
                      'Paragraphs',
                      '${_manifest!.paragraphs.length}',
                      Icons.format_list_numbered,
                    ),
                    SizedBox(height: 8.h),
                    _buildBookStat(
                      'Word Count',
                      '${_getTotalWordCount()}',
                      Icons.text_fields,
                    ),
                  ],
                  if (!book.isDownloaded) ...[
                    SizedBox(height: 8.h),
                    _buildBookStat(
                      'File Size',
                      '${book.fileSizeMb.toStringAsFixed(1)} MB',
                      Icons.storage,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.book,
        size: 48.sp,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildBookStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: Theme.of(context).colorScheme.secondary,
        ),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  bool _isSuccessMessage(String message) {
    return message.contains('Download Started Successfully') || 
           message.contains('Your EPUB download has been initiated') ||
           message.contains('✅');
  }

  Widget _buildSuccessCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Download Instructions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _downloadError = null),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            SelectableText(
              _downloadError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ).withTestId('download-success-text', label: 'Download Success Message'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Download Error',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _downloadError = null),
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            SelectableText(
              _downloadError!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ).withTestId('download-error-text', label: 'Download Error Message'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Book book) {
    final libraryState = ref.watch(libraryControllerProvider);
    final isDownloadingThis = libraryState.downloadProgress.containsKey(book.id);
    final downloadProgress = libraryState.downloadProgress[book.id] ?? 0.0;

    if (!book.isDownloaded) {
      if (_isDownloading || isDownloadingThis) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                label: Text('Downloading... ${(downloadProgress * 100).toInt()}%'),
              ),
            ),
            if (downloadProgress > 0) ...[
              SizedBox(height: 8.h),
              LinearProgressIndicator(
                value: downloadProgress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        );
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _downloadBook(book),
          icon: const Icon(Icons.download),
          label: const Text('Download Book'),
        ).asTestButton('download-book-btn', label: 'Download ${book.title}'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _manifest != null ? _startListening : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Listen'),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _manifest != null ? _startReading : null,
            icon: const Icon(Icons.chrome_reader_mode),
            label: const Text('Read'),
          ),
        ),
      ],
    );
  }

  Widget _buildChaptersList() {
    if (_manifest == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chapters',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 16.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _manifest!.chapters.length,
          itemBuilder: (context, index) {
            final chapter = _manifest!.chapters[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '${chapter.id + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(chapter.title),
                subtitle: Text('${chapter.paragraphIds.length} paragraphs'),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _playChapter(chapter),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _getTotalWordCount() {
    if (_manifest == null) return 0;
    return _manifest!.paragraphs.fold(0, (sum, p) => sum + p.wordCount);
  }

  Future<void> _downloadBook(Book book) async {
    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });

    try {
      await ref.read(libraryControllerProvider.notifier).downloadBook(book);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Downloaded "${book.title}" successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View Library',
              textColor: Colors.white,
              onPressed: () => context.go('/'),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadError = _formatError(e.toString());
      });
      
      // Also show a snackbar for immediate feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Download failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _downloadBook(book),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _formatError(String error) {
    // Check if this is actually a success message (browser download guidance)
    if (error.contains('Download Started Successfully') || 
        error.contains('Your EPUB download has been initiated')) {
      return error.replaceAll('Exception: ', '').replaceAll('Exception:', '');
    }
    
    if (error.contains('Failed to fetch')) {
      return 'Network error: Unable to download the book. This might be due to:\n'
             '• Internet connection issues\n'
             '• Server temporarily unavailable\n'
             '• EPUB file not accessible\n\n'
             'Please try again later or check your internet connection.';
    } else if (error.contains('CORS')) {
      return 'Browser security restrictions prevent direct download. '
             'Try using the desktop app for full download functionality.';
    } else if (error.contains('404') || error.contains('Not Found')) {
      return 'Book file not found on server. The EPUB may no longer be available.';
    } else {
      return error.replaceAll('Exception: ', '').replaceAll('Exception:', '');
    }
  }

  void _startListening() {
    context.push('/player/${widget.bookId}');
  }

  void _startReading() {
    // TODO: Navigate to reading mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading mode coming in v0.1'),
      ),
    );
  }

  void _playChapter(Chapter chapter) {
    // TODO: Start playback from specific chapter
    context.push('/player/${widget.bookId}');
  }
}