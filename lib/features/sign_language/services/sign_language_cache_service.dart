import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class SignLanguageCacheService {
  final Dio _dio;
  Directory? _cacheDir;

  SignLanguageCacheService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Directory> get cacheDirectory async {
    if (_cacheDir != null) return _cacheDir!;
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/sign_videos');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _cacheDir = dir;
      return dir;
    } catch (_) {
      // Fallback for non-platform environment / test fixtures
      final temp = Directory.systemTemp.createTempSync('sign_cache_');
      _cacheDir = temp;
      return temp;
    }
  }

  Future<File> getCachedVideoFile(String videoId) async {
    final dir = await cacheDirectory;
    return File('${dir.path}/$videoId.mp4');
  }

  Future<bool> isVideoCached(String videoId) async {
    final file = await getCachedVideoFile(videoId);
    return file.exists();
  }

  /// Downloads video with atomic rename using .tmp file
  Future<File?> downloadVideoAtomic({
    required String videoId,
    required String remoteUrl,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await cacheDirectory;
      final targetFile = File('${dir.path}/$videoId.mp4');
      final tempFile = File('${dir.path}/$videoId.tmp');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await _dio.download(
        remoteUrl,
        tempFile.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      // Atomic rename
      if (await tempFile.exists()) {
        final renamed = await tempFile.rename(targetFile.path);
        return renamed;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final dir = await cacheDirectory;
    if (await dir.exists()) {
      final entities = dir.listSync();
      for (final e in entities) {
        try {
          e.deleteSync(recursive: true);
        } catch (_) {}
      }
    }
  }
}
