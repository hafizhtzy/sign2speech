import 'package:flutter/foundation.dart';

enum SignPublicationStatus {
  draft,
  published,
  archived;

  static SignPublicationStatus fromString(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'published' => .published,
      'archived' => .archived,
      _ => .draft,
    };
  }

  String get dbValue => switch (this) {
    .draft => 'draft',
    .published => 'published',
    .archived => 'archived',
  };
}

@immutable
class SignVideoMetadata {
  final String id;
  final String title;
  final String slug;
  final String gloss;
  final List<String> aliases;
  final String languageType; // 'BISINDO' | 'SIBI'
  final String category;
  final String description;
  final String storageBucket;
  final String storagePath;
  final String? thumbnailPath;
  final int? durationSeconds;
  final String mimeType;
  final int? fileSizeBytes;
  final SignPublicationStatus publicationStatus;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SignVideoMetadata({
    required this.id,
    required this.title,
    required this.slug,
    required this.gloss,
    this.aliases = const [],
    this.languageType = 'BISINDO',
    this.category = 'umum',
    this.description = '',
    this.storageBucket = 'sign-language-videos',
    required this.storagePath,
    this.thumbnailPath,
    this.durationSeconds,
    this.mimeType = 'video/mp4',
    this.fileSizeBytes,
    this.publicationStatus = SignPublicationStatus.draft,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPublished => publicationStatus == SignPublicationStatus.published;
  bool get isDraft => publicationStatus == SignPublicationStatus.draft;
  bool get isArchived => publicationStatus == SignPublicationStatus.archived;

  factory SignVideoMetadata.fromPostgresMap(Map<String, dynamic> map) {
    final now = DateTime.now().toUtc();
    final rawAliases = map['aliases'];
    return SignVideoMetadata(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      slug: (map['slug'] ?? '').toString(),
      gloss: (map['gloss'] ?? '').toString(),
      aliases: rawAliases is List
          ? rawAliases.map((e) => e.toString()).toList()
          : const [],
      languageType: (map['language_type'] ?? 'BISINDO').toString(),
      category: (map['category'] ?? 'umum').toString(),
      description: (map['description'] ?? '').toString(),
      storageBucket:
          (map['storage_bucket'] ?? 'sign-language-videos').toString(),
      storagePath: (map['storage_path'] ?? '').toString(),
      thumbnailPath: map['thumbnail_path']?.toString(),
      durationSeconds: (map['duration_seconds'] as num?)?.toInt(),
      mimeType: (map['mime_type'] ?? 'video/mp4').toString(),
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt(),
      publicationStatus: SignPublicationStatus.fromString(
        map['publication_status']?.toString(),
      ),
      createdBy: map['created_by']?.toString(),
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '')?.toUtc() ??
          now,
      updatedAt:
          DateTime.tryParse(map['updated_at']?.toString() ?? '')?.toUtc() ??
          now,
    );
  }

  Map<String, dynamic> toPostgresMap() {
    return <String, dynamic>{
      if (id.isNotEmpty) 'id': id,
      'title': title.trim(),
      'slug': slug.trim().toLowerCase(),
      'gloss': gloss.trim(),
      'aliases': aliases,
      'language_type': languageType.toUpperCase() == 'SIBI' ? 'SIBI' : 'BISINDO',
      'category': category.trim(),
      'description': description.trim(),
      'storage_bucket': storageBucket,
      'storage_path': storagePath,
      'thumbnail_path': thumbnailPath,
      'duration_seconds': durationSeconds,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'publication_status': publicationStatus.dbValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
