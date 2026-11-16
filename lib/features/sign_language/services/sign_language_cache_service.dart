import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';

/// Thrown when the server does not return a valid video file
/// (e.g. missing object or HTML/JSON error response).
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

  /// Base URL of the Supabase Storage `sign-videos` bucket (Cloud-to-Local ready).
  String get signVideosBaseUrl => AppConstants.signBaseUrl;

  /// Catalog URL inside the Supabase Storage `sign-videos` bucket.
  String get signCatalogUrl => AppConstants.signCatalogUrl;

  SignLanguageCacheService({Dio? dio, Directory? cacheDir})
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
            ) {
    if (cacheDir != null) {
      _cacheDir = cacheDir;
    }
  }

  Future<Directory> get cacheDirectory async {
    if (_cacheDir != null) return _cacheDir!;
    final bool isTestEnv = Platform.environment.containsKey('FLUTTER_TEST') ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTestEnv) {
      final temp = Directory.systemTemp.createTempSync('sign_cache_');
      _cacheDir = temp;
      return temp;
    }
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

      // Reject HTML or JSON error payloads returned with HTTP 200.
      // Allow video/* and application/octet-stream (Supabase Storage default binary MIME).
      final contentType =
          response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ??
              '';
      if (contentType.isNotEmpty &&
          !contentType.startsWith('video/') &&
          !contentType.startsWith('application/octet-stream')) {
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
