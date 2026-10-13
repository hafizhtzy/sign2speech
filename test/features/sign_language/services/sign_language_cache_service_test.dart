import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_cache_service.dart';

class MockDioAdapter implements HttpClientAdapter {
  final Uint8List mockBytes;
  final int statusCode;

  MockDioAdapter({required this.mockBytes, this.statusCode = 200});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody(
      Stream.fromIterable([mockBytes]),
      statusCode,
      headers: {
        Headers.contentLengthHeader: [mockBytes.length.toString()],
        Headers.contentTypeHeader: ['video/mp4'],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SignLanguageCacheService cacheService;
  late Directory tempDir;
  late Dio mockDio;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sign_cache_test_');
    mockDio = Dio();
    final mp4Bytes = Uint8List(1024);
    mp4Bytes[0] = 0;
    mp4Bytes[1] = 0;
    mp4Bytes[2] = 0;
    mp4Bytes[3] = 32;
    mp4Bytes[4] = 0x66; // 'f'
    mp4Bytes[5] = 0x74; // 't'
    mp4Bytes[6] = 0x79; // 'y'
    mp4Bytes[7] = 0x70; // 'p'
    mockDio.httpClientAdapter = MockDioAdapter(
      mockBytes: mp4Bytes,
    );
    cacheService = SignLanguageCacheService(dio: mockDio);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SignLanguageCacheService Tests', () {
    test('Downloads video atomically, reports progress, and saves to file', () async {
      double lastProgress = 0.0;
      final file = await cacheService.downloadVideoAtomic(
        videoId: 'baik_v1',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4',
        onProgress: (p) => lastProgress = p,
      );

      expect(file, isNotNull);
      expect(await file!.exists(), isTrue);
      expect(await file.length(), equals(1024));
      expect(lastProgress, equals(1.0));

      final isCached = await cacheService.isVideoCached('baik_v1');
      expect(isCached, isTrue);
    });

    test('Overwrites target file safely if already downloaded without throwing rename error', () async {
      // First download
      final first = await cacheService.downloadVideoAtomic(
        videoId: 'baik_v1',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4',
      );
      expect(first, isNotNull);
      expect(await first!.exists(), isTrue);

      // Second download with same target videoId (tests collision handling)
      final second = await cacheService.downloadVideoAtomic(
        videoId: 'baik_v1',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4',
      );
      expect(second, isNotNull);
      expect(await second!.exists(), isTrue);
      expect(await second.length(), equals(1024));
    });

    test('clearCache removes downloaded video files and returns accurate count', () async {
      await cacheService.downloadVideoAtomic(
        videoId: 'video_a',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/a_v1.mp4',
      );
      await cacheService.downloadVideoAtomic(
        videoId: 'video_b',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/b_v1.mp4',
      );

      expect(await cacheService.isVideoCached('video_a'), isTrue);
      expect(await cacheService.isVideoCached('video_b'), isTrue);

      final count = await cacheService.clearCache();
      expect(count, greaterThanOrEqualTo(2));
      expect(await cacheService.isVideoCached('video_a'), isFalse);
      expect(await cacheService.isVideoCached('video_b'), isFalse);
    });
  });
}
