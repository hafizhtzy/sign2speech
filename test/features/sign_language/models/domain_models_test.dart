import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/models/landmark_frame.dart';
import 'package:speech2sign/features/sign_language/models/bisindo_prediction.dart';
import 'package:speech2sign/features/sign_language/models/sign_token.dart';
import 'package:speech2sign/features/sign_language/models/sign_video_entry.dart';
import 'package:speech2sign/features/sign_language/models/sign_search_result.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_catalog.dart';

void main() {
  group('LandmarkFrame and Sanitization Tests', () {
    test(
      'sanitizes NaN and infinite coordinates to 0.0 and clamps outliers',
      () {
        final raw = [
          double.nan,
          double.infinity,
          -double.infinity,
          15.5, // should clamp to 10.0
          -12.0, // should clamp to -10.0
          1.25,
        ];

        final sanitized = sanitizeLandmarks(raw);
        expect(sanitized[0], equals(0.0));
        expect(sanitized[1], equals(0.0));
        expect(sanitized[2], equals(0.0));
        expect(sanitized[3], equals(10.0));
        expect(sanitized[4], equals(-10.0));
        expect(sanitized[5], equals(1.25));
      },
    );

    test('LandmarkFrame stores sanitized landmarks and valid status', () {
      final frame = LandmarkFrame(
        landmarks: [double.nan, 0.5, 0.8],
        timestampMs: 12345,
        isValid: true,
      );

      expect(frame.landmarks.length, equals(3));
      expect(frame.landmarks[0], equals(0.0));
      expect(frame.landmarks[1], equals(0.5));
      expect(frame.timestampMs, equals(12345));
      expect(frame.isValid, isTrue);
    });
  });

  group('BisindoPrediction & SignToken Tests', () {
    test('BisindoPrediction correctly identifies words and letters', () {
      const predWord = BisindoPrediction(
        label: 'WORD_HALO',
        confidence: 0.88,
        margin: 0.25,
        isLetter: false,
      );
      expect(predWord.label, equals('WORD_HALO'));
      expect(predWord.isLetter, isFalse);
      expect(predWord.cleanLabel, equals('Halo'));

      const predLetter = BisindoPrediction(
        label: 'LETTER_A',
        confidence: 0.95,
        margin: 0.40,
        isLetter: true,
      );
      expect(predLetter.isLetter, isTrue);
      expect(predLetter.cleanLabel, equals('A'));
    });

    test('SignToken stores token value, type, and timestamp', () {
      final now = DateTime.now();
      final token = SignToken(
        value: 'Halo',
        type: SignTokenType.word,
        timestamp: now,
      );
      expect(token.value, equals('Halo'));
      expect(token.type, equals(SignTokenType.word));
      expect(token.timestamp, equals(now));
    });
  });

  group('SignVideoEntry and Search Result Tests', () {
    test('SignVideoEntry serialization and alias matching', () {
      const entry = SignVideoEntry(
        id: 'terima_kasih',
        label: 'Terima Kasih',
        aliases: ['makasih', 'nuhun', 'thank you'],
        category: 'salam',
        assetPath: 'assets/videos/bisindo/terima_kasih_v1.mp4',
        remoteUrl:
            'https://hajicare-sign.web.app/videos/bisindo/terima_kasih_v1.mp4',
      );

      expect(entry.matches('makasih'), isTrue);
      expect(entry.matches('terima kasih'), isTrue);
      expect(entry.matches('selamat'), isFalse);
    });

    test('SignSearchResult stores query and matched entries', () {
      const entry = SignVideoEntry(
        id: 'halo',
        label: 'Halo',
        aliases: ['hai'],
        category: 'salam',
        assetPath: 'assets/videos/bisindo/halo_v1.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/halo_v1.mp4',
      );

      final result = SignSearchResult(
        query: 'halo',
        matchedEntries: [entry],
        matchType: SearchMatchType.exact,
      );

      expect(result.matchedEntries.length, equals(1));
      expect(result.matchType, equals(SearchMatchType.exact));
      expect(result.hasMatch, isTrue);
    });

    test('SignLanguageCatalog contains predefined public vocabulary', () {
      final catalog = SignLanguageCatalog.defaultCatalog();
      expect(catalog.entries.isNotEmpty, isTrue);
      expect(catalog.findExact('Terima Kasih'), isNotNull);
      expect(catalog.findByAlias('makasih'), isNotNull);
    });
  });
}
