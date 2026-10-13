import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_catalog.dart';
import 'package:speech2sign/features/sign_language/models/sign_search_result.dart';
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

  group('Hierarchical Search Tests', () {
    test('Tier 1: Exact match finds full phrase', () async {
      final result = await repository.searchSign('terima kasih', 'bisindo');
      expect(result.matchType, equals(SearchMatchType.exact));
      expect(result.matchedEntries.length, equals(1));
      expect(result.matchedEntries.first.label, equals('Terima Kasih'));
    });

    test('Tier 2: Alias match maps synonyms correctly', () async {
      final resultKarcis = await repository.searchSign('karcis', 'bisindo');
      expect(resultKarcis.matchType, equals(SearchMatchType.alias));
      expect(resultKarcis.matchedEntries.first.label, equals('Tiket'));

      final resultTolong = await repository.searchSign('tolong', 'bisindo');
      expect(resultTolong.matchType, equals(SearchMatchType.alias));
      expect(resultTolong.matchedEntries.first.label, equals('Bantu'));
    });

    test(
      'Tier 3: Tokenized match splits compound sentence into sequential words',
      () async {
        final result = await repository.searchSign(
          'saya mau beli tiket',
          'bisindo',
        );
        expect(result.matchType, equals(SearchMatchType.tokenized));
        expect(result.matchedEntries.length, equals(4));
        expect(result.matchedEntries[0].label, equals('Saya'));
        expect(result.matchedEntries[1].label, equals('Mau'));
        expect(result.matchedEntries[2].label, equals('Beli'));
        expect(result.matchedEntries[3].label, equals('Tiket'));
      },
    );

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
    test('Resolves fallback remote CDN URL when local asset/cache is not available', () async {
      final entry = catalog.findExact('Terima Kasih')!;
      final source = await repository.resolveVideoSource(entry);
      expect(
        source,
        equals(
          'https://hajicare-sign.web.app/videos/bisindo/terima_kasih_v1.mp4',
        ),
      );
    });
  });
}
