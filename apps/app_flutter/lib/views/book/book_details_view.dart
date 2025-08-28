import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/library_controller.dart';
import '../../controllers/player_controller.dart';
import '../../models/book.dart';
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
          ? const Center(child: Text('Book not found'))
          : _isLoadingManifest
              ? const Center(child: CircularProgressIndicator())
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

  Widget _buildActionButtons(Book book) {
    if (!book.isDownloaded) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _downloadBook(book),
          icon: const Icon(Icons.download),
          label: const Text('Download Book'),
        ),
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

  void _downloadBook(Book book) {
    ref.read(libraryControllerProvider.notifier).downloadBook(book);
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