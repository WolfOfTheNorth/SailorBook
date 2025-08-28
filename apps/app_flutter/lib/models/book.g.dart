// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      coverUrl: json['coverUrl'] as String?,
      downloadUrl: json['downloadUrl'] as String,
      fileSizeMb: (json['fileSizeMb'] as num).toDouble(),
      downloadedAt: json['downloadedAt'] == null
          ? null
          : DateTime.parse(json['downloadedAt'] as String),
      localPath: json['localPath'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'coverUrl': instance.coverUrl,
      'downloadUrl': instance.downloadUrl,
      'fileSizeMb': instance.fileSizeMb,
      'downloadedAt': instance.downloadedAt?.toIso8601String(),
      'localPath': instance.localPath,
      'isDownloaded': instance.isDownloaded,
    };

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      paragraphIds: (json['paragraphIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'paragraphIds': instance.paragraphIds,
    };

Paragraph _$ParagraphFromJson(Map<String, dynamic> json) => Paragraph(
      id: (json['id'] as num).toInt(),
      chapterId: (json['chapterId'] as num).toInt(),
      text: json['text'] as String,
      wordCount: (json['wordCount'] as num).toInt(),
    );

Map<String, dynamic> _$ParagraphToJson(Paragraph instance) => <String, dynamic>{
      'id': instance.id,
      'chapterId': instance.chapterId,
      'text': instance.text,
      'wordCount': instance.wordCount,
    };

PlaybackPosition _$PlaybackPositionFromJson(Map<String, dynamic> json) =>
    PlaybackPosition(
      chapterId: (json['chapterId'] as num).toInt(),
      paragraphId: (json['paragraphId'] as num).toInt(),
      offsetMs: (json['offsetMs'] as num).toInt(),
    );

Map<String, dynamic> _$PlaybackPositionToJson(PlaybackPosition instance) =>
    <String, dynamic>{
      'chapterId': instance.chapterId,
      'paragraphId': instance.paragraphId,
      'offsetMs': instance.offsetMs,
    };

BookManifest _$BookManifestFromJson(Map<String, dynamic> json) => BookManifest(
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      chapters: (json['chapters'] as List<dynamic>)
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      paragraphs: (json['paragraphs'] as List<dynamic>)
          .map((e) => Paragraph.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastPosition: json['lastPosition'] == null
          ? null
          : PlaybackPosition.fromJson(
              json['lastPosition'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BookManifestToJson(BookManifest instance) =>
    <String, dynamic>{
      'bookId': instance.bookId,
      'title': instance.title,
      'author': instance.author,
      'chapters': instance.chapters,
      'paragraphs': instance.paragraphs,
      'lastPosition': instance.lastPosition,
    };
