import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_catalog.dart';
import 'package:speech2sign/features/sign_language/models/sign_search_result.dart';
import 'package:speech2sign/features/sign_language/models/sign_video_entry.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_config.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SignLanguageCatalog catalog;
  late SignLanguageConfig config;
  late SignLanguageRepository repository;

  setUp(() {
    catalog = SignLanguageCatalog.defaultCatalog();
    config = const SignLanguageConfig(baseUrl: 'https://hajicare-sign.web.app');
    repository = SignLanguageRepository(catalog: catalog, config: config);
  });

  group('Hierarchical Search Tests with Official Haji-Sign Catalog', () {
    test('Tier 1: Exact match finds full phrase for BISINDO and SIBI', () async {
      final resultBisindo = await repository.searchSign('baik', 'bisindo');
      expect(resultBisindo.matchType, equals(SearchMatchType.exact));
      expect(resultBisindo.matchedEntries.length, equals(1));
      expect(resultBisindo.matchedEntries.first.label, equals('Baik'));
      expect(
        resultBisindo.matchedEntries.first.remoteUrl,
        equals('https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4'),
      );

      final resultSibi = await repository.searchSign('obat', 'sibi');
      expect(resultSibi.matchType, equals(SearchMatchType.exact));
      expect(resultSibi.matchedEntries.length, equals(1));
      expect(resultSibi.matchedEntries.first.label, equals('Obat'));
      expect(
        resultSibi.matchedEntries.first.remoteUrl,
        equals('https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4'),
      );
    });

    test('Smart Cross-Language Fallback: Finds SIBI "Obat" even when search is in BISINDO', () async {
      final result = await repository.searchSign('obat', 'bisindo');
      expect(result.isFound, isTrue);
      expect(result.matchedEntries.first.label, equals('Obat'));
      expect(result.matchedEntries.first.signSystem, equals('sibi'));
      expect(
        result.matchedEntries.first.remoteUrl,
        equals('https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4'),
      );
    });

    test('Tier 2: Alias match maps synonyms correctly to official catalog items', () async {
      // Alias 'resep' -> 'Obat'
      final resultResep = await repository.searchSign('resep', 'sibi');
      expect(resultResep.matchType, equals(SearchMatchType.alias));
      expect(resultResep.matchedEntries.first.label, equals('Obat'));

      // Alias 'tolong' -> 'Bantu'
      final resultTolong = await repository.searchSign('tolong', 'sibi');
      expect(resultTolong.matchType, equals(SearchMatchType.alias));
      expect(resultTolong.matchedEntries.first.label, equals('Bantu'));

      // Alias 'bagus' -> 'Baik'
      final resultBagus = await repository.searchSign('bagus', 'bisindo');
      expect(resultBagus.matchType, equals(SearchMatchType.alias));
      expect(resultBagus.matchedEntries.first.label, equals('Baik'));
    });

    test('Tier 3: Tokenized match splits compound sentence into sequential words', () async {
      final result = await repository.searchSign('kami minum obat', 'bisindo');
      expect(result.matchType, equals(SearchMatchType.tokenized));
      expect(result.matchedEntries.length, equals(3));
      expect(result.matchedEntries[0].label, equals('Kami'));
      expect(result.matchedEntries[1].label, equals('Minum'));
      expect(result.matchedEntries[2].label, equals('Obat'));
    });

    test('Unknown query returns empty result with none matchType', () async {
      final result = await repository.searchSign(
        'astronomikal kosmis',
        'bisindo',
      );
      expect(result.matchType, equals(SearchMatchType.none));
      expect(result.matchedEntries, isEmpty);
    });
  });

  group('3-Tier Video Source Resolution Tests', () {
    test('Tier 1: Resolves local bundled offline asset directly when available', () async {
      final entry = catalog.findExact('Terima Kasih')!;
      final source = await repository.resolveVideoSource(entry);
      expect(source.source, equals(SignVideoSource.asset));
      expect(
        source.path,
        equals('assets/sign_language/offline/bisindo/kalimat/Terima_Kasih.mp4'),
      );
    });

    test('Tier 3: Resolves remote CDN from https://hajicare-sign.web.app for online vocabulary (Obat)', () async {
      final entry = catalog.findExact('Obat')!;
      expect(entry.remoteUrl, equals('https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4'));
      final source = await repository.resolveVideoSource(entry);
      expect(
        source.path.contains('obat') || source.path.contains('hajicare-sign.web.app'),
        isTrue,
      );
    });

    test('CDN URL convention produces consistent paths for bisindo and sibi', () {
      expect(
        SignVideoEntry.buildCdnUrl(word: 'baik', signSystem: 'bisindo'),
        equals('https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4'),
      );
      expect(
        SignVideoEntry.buildCdnUrl(word: 'obat', signSystem: 'sibi'),
        equals('https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4'),
      );

      final dynamicBisindo = repository.createDynamicEntry('baik', 'bisindo');
      expect(
        dynamicBisindo.remoteUrl,
        equals('https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4'),
      );

      final dynamicSibi = repository.createDynamicEntry('obat', 'sibi');
      expect(
        dynamicSibi.remoteUrl,
        equals('https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4'),
      );
    });

    test('Resolves online video "baik" with CDN URL https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4', () async {
      final entry = catalog.findExact('Baik')!;
      expect(entry.remoteUrl, equals('https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4'));
      final source = await repository.resolveVideoSource(entry);
      expect(source.remoteUrl, equals('https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4'));
      expect(source.path.isNotEmpty, isTrue);
    });

    test('getAvailableVideos returns all catalog entries with valid source resolution', () async {
      final videos = await repository.getAvailableVideos(language: 'bisindo');
      expect(videos.isNotEmpty, isTrue);
      expect(videos.any((v) => v.label.toLowerCase() == 'baik'), isTrue);
    });
  });

  group('Haji-Sign JSON Catalog Parser Tests', () {
    test('SignLanguageCatalog.fromJson parses official haji_sign_catalog.json file', () async {
      final file = File('assets/sign_language/haji_sign_catalog.json');
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      final parsedCatalog = SignLanguageCatalog.fromJson(data);
      expect(parsedCatalog.entries.length, equals(42));

      final kopiJsonEntry = parsedCatalog.findExact('Kopi');
      expect(kopiJsonEntry, isNotNull);
      expect(kopiJsonEntry!.id, equals('bisindo_kopi'));
      expect(kopiJsonEntry.signSystem, equals('bisindo'));

      final obatEntry = parsedCatalog.findExact('Obat');
      expect(obatEntry, isNotNull);
      expect(obatEntry!.id, equals('sibi_obat'));
      expect(obatEntry.signSystem, equals('sibi'));
      expect(obatEntry.remoteUrl, equals('https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4'));

      final baikEntry = parsedCatalog.findExact('Baik');
      expect(baikEntry, isNotNull);
      expect(baikEntry!.id, equals('bisindo_baik'));
      expect(baikEntry.signSystem, equals('bisindo'));
      expect(baikEntry.remoteUrl, equals('https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4'));
    });
  });
}
