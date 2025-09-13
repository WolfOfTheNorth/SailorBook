import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:epubx/epubx.dart';

import '../../controllers/library_controller.dart';

class ReaderView extends ConsumerStatefulWidget {
  final String bookId;

  const ReaderView({super.key, required this.bookId});

  @override
  ConsumerState<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends ConsumerState<ReaderView> {
  bool _loading = true;
  String? _error;
  List<_ChapterData> _chapters = const [];
  int _currentChapter = 0;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Find the downloaded book
      var libraryState = ref.read(libraryControllerProvider);
      var book = libraryState.downloadedBooks
          .where((b) => b.id == widget.bookId)
          .firstOrNull;

      if (book == null) {
        await ref.read(libraryControllerProvider.notifier).loadDownloadedBooks();
        libraryState = ref.read(libraryControllerProvider);
        book = libraryState.downloadedBooks
            .where((b) => b.id == widget.bookId)
            .firstOrNull;
      }

      if (book == null || book.localPath == null) {
        setState(() {
          _error = 'Book not found locally. Please download it again.';
          _loading = false;
        });
        return;
      }

      final epubPath = '${book.localPath}/book.epub';
      final file = File(epubPath);
      if (!await file.exists()) {
        setState(() {
          _error = 'EPUB file is missing. Try re-downloading the book.';
          _loading = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);

      final chapters = <_ChapterData>[];
      void collect(EpubChapter chapter) {
        final title = chapter.Title?.trim().isNotEmpty == true
            ? chapter.Title!.trim()
            : 'Untitled Chapter';
        final html = chapter.HtmlContent ?? '';
        final text = _stripHtml(html);
        chapters.add(_ChapterData(title: title, text: text));
        if (chapter.SubChapters != null) {
          for (final sub in chapter.SubChapters!) {
            collect(sub);
          }
        }
      }

      for (final ch in (epubBook.Chapters ?? const <EpubChapter>[])) {
        collect(ch);
      }

      setState(() {
        _chapters = chapters.isNotEmpty
            ? chapters
            : [
                _ChapterData(
                  title: 'Book',
                  text: _stripHtml((epubBook.Content?.Html?.values
                              .map((d) => d.Content)
                              .join('\n')) ??
                          ''),
                ),
              ];
        _currentChapter = 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to open EPUB: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader'),
        actions: _chapters.isNotEmpty
            ? [
                Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _currentChapter,
                      onChanged: (i) => setState(() => _currentChapter = i ?? 0),
                      items: List.generate(_chapters.length, (i) {
                        final label = _chapters[i].title;
                        return DropdownMenuItem<int>(
                          value: i,
                          child: Text(
                            label.length > 32 ? '${label.substring(0, 32)}…' : label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48.w, color: Theme.of(context).colorScheme.error),
              SizedBox(height: 12.h),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: _loadBook,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final chapter = _chapters[_currentChapter];
    return Scrollbar(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: SelectableText(
          chapter.text,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ),
    );
  }

  static String _stripHtml(String html) {
    // Basic HTML tag removal and entity cleanup
    final noTags = html.replaceAll(RegExp(r"<[^>]+>"), ' ');
    final collapsed = noTags.replaceAll(RegExp(r"\s+"), ' ').trim();
    // Minimal entity decoding for common entities
    return collapsed
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}

class _ChapterData {
  final String title;
  final String text;
  const _ChapterData({required this.title, required this.text});
}
