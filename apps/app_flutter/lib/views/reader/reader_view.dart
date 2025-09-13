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
  int _currentPage = 0;
  List<String> _currentPages = const [];

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
        final cleanedHtml = _removeInternetArchiveArtifactsHtml(html);
        final text = _stripHtmlPreserveLines(cleanedHtml);
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

      // If the EPUB didn't provide a ToC, try to build a sensible fallback
      if (chapters.isEmpty) {
        final contentFiles = (epubBook.Content?.Html?.values.toList()) ?? const [];
        final fallbackChapters = <_ChapterData>[];
        int sectionIndex = 1;
        for (final f in contentFiles) {
          final html = f.Content ?? '';
          if (html.trim().isEmpty) continue;
          final titleFromHeading = _firstHeadingFromHtml(html);
          final text = _stripHtmlPreserveLines(_removeInternetArchiveArtifactsHtml(html));
          if (text.isEmpty) continue;
          fallbackChapters.add(_ChapterData(
            title: titleFromHeading ?? 'Section $sectionIndex',
            text: text,
          ));
          sectionIndex++;
        }
        if (fallbackChapters.isNotEmpty) {
          chapters.addAll(fallbackChapters);
        } else {
          // Ultimate fallback: single large chapter
          chapters.add(_ChapterData(
            title: 'Book',
            text: _stripHtmlPreserveLines(_removeInternetArchiveArtifactsHtml(
                (epubBook.Content?.Html?.values.map((d) => d.Content).join('\n')) ?? '')),
          ));
        }
      }

      setState(() {
        _chapters = chapters;
        _currentChapter = 0;
        _loading = false;
      });
      _resetPagination();
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
                      onChanged: (i) {
                        setState(() {
                          _currentChapter = i ?? 0;
                        });
                        _resetPagination();
                      },
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
                if (_currentPages.isNotEmpty) ...[
                  IconButton(
                    tooltip: 'Previous page',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage -= 1)
                        : null,
                  ),
                  Center(
                    child: Text(
                      'Page ${_currentPage + 1}/${_currentPages.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next page',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (_currentPage + 1) < _currentPages.length
                        ? () => setState(() => _currentPage += 1)
                        : null,
                  ),
                  SizedBox(width: 8.w),
                ],
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
    final pageText = _currentPages.isNotEmpty
        ? _currentPages[_currentPage]
        : chapter.text;
    final hasText = pageText.trim().isNotEmpty;
    return Scrollbar(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: hasText
            ? SelectableText(
                pageText,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_outlined, size: 48.w),
                    SizedBox(height: 12.h),
                    const Text('No content to display for this section.'),
                  ],
                ),
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

  static String _stripHtmlPreserveLines(String html) {
    if (html.isEmpty) return '';
    var s = html;
    // Convert common block-level boundaries to newlines (case-insensitive)
    s = s.replaceAll(
      RegExp(r'</?(br|p|div|li|tr|td|blockquote|h[1-6])[^>]*>', caseSensitive: false),
      '\n',
    );
    // Remove remaining tags
    s = s.replaceAll(RegExp(r'<[^>]+>'), ' ');
    // Decode a few common entities
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    // Normalize spaces but keep newlines
    s = s.replaceAll(RegExp(r'[ \t\f\v]+'), ' ');
    // Collapse many blank lines
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }

  static String? _firstHeadingFromHtml(String html) {
    // Use [\s\S] instead of dotAll for broad web compatibility
    final match = RegExp(r'<h[1-3][^>]*>([\s\S]*?)</h[1-3]>', caseSensitive: false).firstMatch(html);
    if (match == null) return null;
    final raw = match.group(1) ?? '';
    final text = raw.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isNotEmpty ? text : null;
  }

  static String _removeInternetArchiveArtifactsHtml(String html) {
    if (html.isEmpty) return html;
    var s = html;
    // Remove IA preface paragraph(s) containing these phrases (case-insensitive)
    final phrases = [
      'This book was produced in EPUB format by the Internet Archive',
      'Created with hocr-to-epub',
      'Digitized by the Internet Archive',
      'The text on this page is estimated to be only',
    ];
    for (final p in phrases) {
      final escaped = RegExp.escape(p);
      // Remove simple blocks that contain the phrase (non-greedy, shallow)
      final tagPattern = RegExp('<[^>]*>[^<]*$escaped[^<]*</[^>]*>', caseSensitive: false);
      s = s.replaceAll(tagPattern, '');
      // Also remove any remaining plain-text occurrences
      s = s.replaceAll(RegExp(escaped, caseSensitive: false), '');
    }
    // Remove standalone page markers like "Page 12" even if not wrapped in tags
    s = s.replaceAll(
      RegExp(r'^\s*Page\s+\d+\s*$', multiLine: true, caseSensitive: false),
      '',
    );
    // Safety: if cleanup removes everything, fall back to original html
    if (s.trim().isEmpty) return html;
    return s;
  }

  void _resetPagination() {
    if (_chapters.isEmpty) {
      setState(() {
        _currentPages = const [];
        _currentPage = 0;
      });
      return;
    }
    final text = _chapters[_currentChapter].text;
    final pages = _splitIntoPages(text, maxChars: 1800);
    setState(() {
      _currentPages = pages;
      _currentPage = 0;
    });
  }

  static List<String> _splitIntoPages(String text, {int maxChars = 1800}) {
    if (text.isEmpty) return [''];
    if (text.length <= maxChars) return [text];
    final words = text.split(RegExp(r'\s+'));
    final pages = <String>[];
    var buffer = StringBuffer();
    var currentLen = 0;
    for (final w in words) {
      final addLen = currentLen == 0 ? w.length : 1 + w.length; // include space when not first
      if (currentLen + addLen > maxChars) {
        pages.add(buffer.toString().trim());
        buffer = StringBuffer();
        currentLen = 0;
      }
      if (currentLen > 0) buffer.write(' ');
      buffer.write(w);
      currentLen += addLen;
    }
    final last = buffer.toString().trim();
    if (last.isNotEmpty || pages.isEmpty) pages.add(last);
    return pages;
  }
}

class _ChapterData {
  final String title;
  final String text;
  const _ChapterData({required this.title, required this.text});
}
