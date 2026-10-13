import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown when the server does not return a valid video file
/// (e.g. Firebase Hosting serving its HTML 404 page with HTTP 200).
class SignVideoNotAvailableException implements Exception {
  final String url;
  final String reason;
  const SignVideoNotAvailableException(this.url, this.reason);

  @override
  String toString() => 'SignVideoNotAvailableException($reason): $url';
}

class SignLanguageCacheService {
  final Dio _dio;
  Directory? _cacheDir;

  SignLanguageCacheService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'User-Agent': 'Sign2Speech/1.0',
                  'Accept-Encoding': 'identity',
                },
              ),
            );

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

  /// Checks the ISO-BMFF signature: bytes 4..7 must be `ftyp`.
  /// Rejects HTML error pages saved with a `.mp4` extension.
  static Future<bool> isValidMp4File(File file) async {
    RandomAccessFile? raf;
    try {
      if (!await file.exists()) return false;
      if (await file.length() < 12) return false;
      raf = await file.open();
      final header = await raf.read(12);
      if (header.length < 8) return false;
      return header[4] == 0x66 && // f
          header[5] == 0x74 && // t
          header[6] == 0x79 && // y
          header[7] == 0x70; // p
    } catch (_) {
      return false;
    } finally {
      await raf?.close();
    }
  }

  /// Returns true only if the cached file exists AND is a real MP4.
  /// Corrupt files (e.g. cached HTML) are deleted so they get re-resolved.
  Future<bool> isVideoCached(String videoId) async {
    final file = await getCachedVideoFile(videoId);
    if (!await file.exists()) return false;
    if (await isValidMp4File(file)) return true;
    debugPrint('[SignCache] Removing invalid cached file: ${file.path}');
    try {
      await file.delete();
    } catch (_) {}
    return false;
  }

  /// Downloads a video into a `.tmp` file, validates it, then atomically
  /// moves it into place.
  ///
  /// Returns `null` on network failure. Throws
  /// [SignVideoNotAvailableException] if the server has no video at [remoteUrl].
  Future<File?> downloadVideoAtomic({
    required String videoId,
    required String remoteUrl,
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    final dir = await cacheDirectory;
    final targetFile = File('${dir.path}/$videoId.mp4');
    final tempFile = File('${dir.path}/$videoId.tmp');

    Future<void> deleteTemp() async {
      try {
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {}
    }

    await deleteTemp();

    try {
      final response = await _dio.download(
        remoteUrl,
        tempFile.path,
        cancelToken: cancelToken,
        options: Options(headers: {'Accept-Encoding': 'identity'}),
        onReceiveProgress: (received, total) {
          if (onProgress == null) return;
          if (total > 0) {
            onProgress((received / total).clamp(0.0, 0.99));
          } else if (received > 0) {
            onProgress((received / 524288).clamp(0.0, 0.95));
          }
        },
      );

      // Firebase Hosting returns HTTP 200 + text/html for missing files.
      final contentType =
          response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ??
              '';
      if (contentType.isNotEmpty && !contentType.startsWith('video/')) {
        await deleteTemp();
        throw SignVideoNotAvailableException(
          remoteUrl,
          'content-type $contentType',
        );
      }

      if (!await isValidMp4File(tempFile)) {
        await deleteTemp();
        throw SignVideoNotAvailableException(remoteUrl, 'bukan file MP4');
      }

      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }

      File result;
      try {
        result = await tempFile.rename(targetFile.path);
      } catch (_) {
        await tempFile.copy(targetFile.path);
        await deleteTemp();
        result = targetFile;
      }
      onProgress?.call(1.0);
      return result;
    } on SignVideoNotAvailableException {
      rethrow;
    } on DioException catch (e) {
      await deleteTemp();
      if (e.response?.statusCode == 404) {
        throw SignVideoNotAvailableException(remoteUrl, 'HTTP 404');
      }
      debugPrint('[SignCache] Download failed ($remoteUrl): ${e.message}');
      return null;
    } catch (e) {
      await deleteTemp();
      debugPrint('[SignCache] Download failed ($remoteUrl): $e');
      return null;
    }
  }

  Future<int> clearCache() async {
    int deletedCount = 0;
    final dir = await cacheDirectory;
    if (await dir.exists()) {
      for (final e in dir.listSync()) {
        try {
          if (e is File &&
              (e.path.endsWith('.mp4') || e.path.endsWith('.tmp'))) {
            e.deleteSync();
            deletedCount++;
          }
        } catch (_) {}
      }
    }
    return deletedCount;
  }
}
