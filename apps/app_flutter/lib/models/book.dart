import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class Book extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String downloadUrl;
  final double fileSizeMb;
  final DateTime? downloadedAt;
  final String? localPath;
  final bool isDownloaded;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.downloadUrl,
    required this.fileSizeMb,
    this.downloadedAt,
    this.localPath,
    this.isDownloaded = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? coverUrl,
    String? downloadUrl,
    double? fileSizeMb,
    DateTime? downloadedAt,
    String? localPath,
    bool? isDownloaded,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        coverUrl,
        downloadUrl,
        fileSizeMb,
        downloadedAt,
        localPath,
        isDownloaded,
      ];
}

@JsonSerializable()
class Chapter extends Equatable {
  final int id;
  final String title;
  final List<int> paragraphIds;

  const Chapter({
    required this.id,
    required this.title,
    required this.paragraphIds,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => _$ChapterFromJson(json);
  Map<String, dynamic> toJson() => _$ChapterToJson(this);

  @override
  List<Object?> get props => [id, title, paragraphIds];
}

@JsonSerializable()
class Paragraph extends Equatable {
  final int id;
  final int chapterId;
  final String text;
  final int wordCount;

  const Paragraph({
    required this.id,
    required this.chapterId,
    required this.text,
    required this.wordCount,
  });

  factory Paragraph.fromJson(Map<String, dynamic> json) => _$ParagraphFromJson(json);
  Map<String, dynamic> toJson() => _$ParagraphToJson(this);

  @override
  List<Object?> get props => [id, chapterId, text, wordCount];
}

@JsonSerializable()
class PlaybackPosition extends Equatable {
  final int chapterId;
  final int paragraphId;
  final int offsetMs;

  const PlaybackPosition({
    required this.chapterId,
    required this.paragraphId,
    required this.offsetMs,
  });

  factory PlaybackPosition.fromJson(Map<String, dynamic> json) => 
      _$PlaybackPositionFromJson(json);
  Map<String, dynamic> toJson() => _$PlaybackPositionToJson(this);

  @override
  List<Object?> get props => [chapterId, paragraphId, offsetMs];
}

@JsonSerializable()
class BookManifest extends Equatable {
  final String bookId;
  final String title;
  final String author;
  final List<Chapter> chapters;
  final List<Paragraph> paragraphs;
  final PlaybackPosition? lastPosition;

  const BookManifest({
    required this.bookId,
    required this.title,
    required this.author,
    required this.chapters,
    required this.paragraphs,
    this.lastPosition,
  });

  factory BookManifest.fromJson(Map<String, dynamic> json) => 
      _$BookManifestFromJson(json);
  Map<String, dynamic> toJson() => _$BookManifestToJson(this);

  @override
  List<Object?> get props => [
        bookId,
        title,
        author,
        chapters,
        paragraphs,
        lastPosition,
      ];
}