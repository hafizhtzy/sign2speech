import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/supabase/supabase_result.dart';
import '../../../sign_language/models/sign_video_entry.dart';
import '../../../sign_language/services/sign_language_cache_service.dart';
import '../../domain/models/sign_video_metadata.dart';

/// Supabase Data Layer service for Admin Sign Language Video Management (`Phase 5`).
///
/// Enforces:
/// 1. Strict MP4 / WebM MIME & file size validation (<= 50 MB) + ISO-BMFF `ftyp` header check.
/// 2. Upload to private bucket `sign-language-videos`.
/// 3. Compensation delete on Storage if database metadata insertion fails.
/// 4. Explicit separation between reference video library and MotionGRU AI dataset.
class SupabaseAdminSignVideoService {
  static const int maxVideoSizeBytes = 50 * 1024 * 1024; // 50 MB

  final SupabaseClient? _customSupabase;

  SupabaseAdminSignVideoService({SupabaseClient? supabase})
    : _customSupabase = supabase;

  SupabaseClient? get _supabase {
    if (_customSupabase != null) return _customSupabase;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Validates a candidate video file before upload.
  static Future<SupabaseResult<int>> validateVideoFile(File file) async {
    if (!await file.exists()) {
      return const SupabaseFailure('File video tidak ditemukan.');
    }
    final length = await file.length();
    if (length <= 0) {
      return const SupabaseFailure('File video kosong.');
    }
    if (length > maxVideoSizeBytes) {
      return const SupabaseFailure(
        'Ukuran file video melebihi batas maksimum 50 MB.',
      );
    }

    final lowerPath = file.path.toLowerCase();
    if (!lowerPath.endsWith('.mp4')) {
      return const SupabaseFailure(
        'Format file tidak didukung. Gunakan video MP4 (.mp4) dengan codec H.264.',
      );
    }

    final isValidMp4 = await SignLanguageCacheService.isValidMp4File(file);
    if (!isValidMp4) {
      return const SupabaseFailure(
        'Header file MP4 tidak valid (bukan kontainer ISO-BMFF / ftyp yang sah).',
      );
    }

    return SupabaseSuccess(length);
  }

  Future<SupabaseResult<List<SignVideoMetadata>>> fetchVideos({
    String? languageType,
    SignPublicationStatus? status,
  }) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseSuccess(<SignVideoMetadata>[]);
    }
    try {
      var query = client.from('sign_language_videos').select();
      if (languageType != null && languageType.isNotEmpty) {
        query = query.eq('language_type', languageType.toUpperCase());
      }
      if (status != null) {
        query = query.eq('publication_status', status.dbValue);
      }
      final rows = await query.order('created_at', ascending: false);
      final list = rows
          .map(
            (r) => SignVideoMetadata.fromPostgresMap(
              Map<String, dynamic>.from(r),
            ),
          )
          .toList();
      return SupabaseSuccess(list);
    } catch (e) {
      return SupabaseFailure('Gagal memuat daftar video bahasa isyarat.', e);
    }
  }

  /// Uploads a validated MP4 file to `sign-language-videos` and saves its metadata
  /// in `public.sign_language_videos` with automatic Storage compensation cleanup
  /// if metadata persistence fails.
  Future<SupabaseResult<SignVideoMetadata>> uploadAndSaveVideoMetadata({
    required File videoFile,
    required String title,
    required String gloss,
    required String languageType,
    required String category,
    String description = '',
    List<String> aliases = const [],
    int? durationSeconds,
    SignPublicationStatus initialStatus = SignPublicationStatus.draft,
    bool Function()? isCancelled,
  }) async {
    final validation = await validateVideoFile(videoFile);
    final int fileSize;
    switch (validation) {
      case SupabaseFailure(:final errorMessage):
        return SupabaseFailure(errorMessage);
      case SupabaseSuccess(:final data):
        fileSize = data;
    }

    if (isCancelled?.call() == true) {
      return const SupabaseFailure('Unggahan video dibatalkan oleh pengguna.');
    }

    final client = _supabase;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      return const SupabaseFailure('Sesi Admin belum terautentikasi.');
    }

    final cleanLang =
        languageType.trim().toUpperCase() == 'SIBI' ? 'SIBI' : 'BISINDO';
    final slug = SignVideoEntry.formatSlug(gloss);
    if (slug.isEmpty) {
      return const SupabaseFailure('Kata/frasa isyarat (gloss) tidak valid.');
    }

    final storagePath =
        'videos/${cleanLang.toLowerCase()}/${slug}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final bucket = AppConstants.signLanguageVideosBucket;

    try {
      await client.storage.from(bucket).upload(
            storagePath,
            videoFile,
            fileOptions: const FileOptions(
              contentType: 'video/mp4',
              upsert: true,
            ),
          );

      if (isCancelled?.call() == true) {
        await client.storage.from(bucket).remove([storagePath]);
        return const SupabaseFailure('Unggahan video dibatalkan.');
      }

      try {
        final payload = <String, dynamic>{
          'title': title.trim(),
          'slug': slug,
          'gloss': gloss.trim(),
          'aliases': aliases,
          'language_type': cleanLang,
          'category': category.trim().isEmpty ? 'umum' : category.trim(),
          'description': description.trim(),
          'storage_bucket': bucket,
          'storage_path': storagePath,
          'duration_seconds': durationSeconds,
          'mime_type': 'video/mp4',
          'file_size_bytes': fileSize,
          'publication_status': initialStatus.dbValue,
          'created_by': uid,
          'updated_by': uid,
          if (initialStatus == SignPublicationStatus.published)
            'published_at': DateTime.now().toUtc().toIso8601String(),
        };

        final row = await client
            .from('sign_language_videos')
            .upsert(payload, onConflict: 'language_type,slug')
            .select()
            .single();

        await client.rpc(
          'write_audit_log',
          params: <String, dynamic>{
            'p_action': 'sign_video_uploaded',
            'p_entity_type': 'sign_language_videos',
            'p_entity_id': row['id'].toString(),
            'p_after': payload,
          },
        );

        return SupabaseSuccess(
          SignVideoMetadata.fromPostgresMap(Map<String, dynamic>.from(row)),
        );
      } catch (metaErr) {
        // Compensation cleanup: remove uploaded Storage object so Storage & DB never desync
        try {
          await client.storage.from(bucket).remove([storagePath]);
        } catch (_) {}
        return SupabaseFailure(
          'Gagal menyimpan metadata video; file Storage telah dibersihkan kembali.',
          metaErr,
        );
      }
    } catch (e, st) {
      debugPrint('SupabaseAdminSignVideoService.upload error: $e\n$st');
      return SupabaseFailure('Gagal mengunggah file video ke Storage.', e);
    }
  }

  Future<SupabaseResult<SignVideoMetadata>> updateVideoMetadata(
    SignVideoMetadata updated,
  ) async {
    final client = _supabase;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) {
      return const SupabaseFailure('Sesi Admin belum terautentikasi.');
    }
    try {
      final payload = updated.toPostgresMap()..['updated_by'] = uid;
      if (updated.isPublished) {
        payload['published_at'] = DateTime.now().toUtc().toIso8601String();
      } else if (updated.isArchived) {
        payload['archived_at'] = DateTime.now().toUtc().toIso8601String();
      }

      final row = await client
          .from('sign_language_videos')
          .update(payload)
          .eq('id', updated.id)
          .select()
          .single();

      await client.rpc(
        'write_audit_log',
        params: <String, dynamic>{
          'p_action': 'sign_video_${updated.publicationStatus.dbValue}',
          'p_entity_type': 'sign_language_videos',
          'p_entity_id': updated.id,
          'p_after': payload,
        },
      );

      return SupabaseSuccess(
        SignVideoMetadata.fromPostgresMap(Map<String, dynamic>.from(row)),
      );
    } catch (e) {
      return SupabaseFailure('Gagal memperbarui metadata video.', e);
    }
  }

  Future<SupabaseResult<String>> createSignedPreviewUrl(
    SignVideoMetadata video,
  ) async {
    final client = _supabase;
    if (client == null) {
      return const SupabaseFailure('SupabaseClient belum siap.');
    }
    try {
      final url = await client.storage
          .from(video.storageBucket)
          .createSignedUrl(video.storagePath, 3600);
      return SupabaseSuccess(url);
    } catch (e) {
      return SupabaseFailure('Gagal membuat tautan pratinjau video.', e);
    }
  }
}
