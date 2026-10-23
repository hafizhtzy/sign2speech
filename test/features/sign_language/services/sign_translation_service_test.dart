import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/sign_language/services/sign_translation_service.dart';

void main() {
  late SignTranslationService service;

  setUp(() {
    service = SignTranslationService();
  });

  group('SignTranslationService', () {
    test('translates single sign tokens to English accurately', () {
      expect(service.translateToEnglish('Halo'), 'Hello');
      expect(service.translateToEnglish('terima kasih'), 'Thank you');
      expect(service.translateToEnglish('kopi'), 'Coffee');
      expect(service.translateToEnglish('susu'), 'Milk');
      expect(service.translateToEnglish('darurat'), 'Emergency');
      expect(service.translateToEnglish('bantu'), 'Help');
    });

    test('translates common cafe and cashier phrases', () {
      expect(service.translateToEnglish('Pesan Kopi'), 'Order coffee');
      expect(service.translateToEnglish('less ice'), 'Less ice');
      expect(service.translateToEnglish('kurang gula'), 'Less sugar');
      expect(service.translateToEnglish('bayar qris'), 'Pay with QRIS');
      expect(
        service.translateToEnglish('saya mau pesan kopi'),
        'I would like to order coffee',
      );
      expect(
        service.translateToEnglish('tolong dibungkus untuk dibawa pulang'),
        'Please pack it for takeaway',
      );
    });

    test('handles tokenized multi-word sentences via fallback', () {
      final result = service.translateToEnglish('saya makan obat');
      expect(result.toLowerCase(), contains('i'));
      expect(result.toLowerCase(), contains('eat'));
      expect(result.toLowerCase(), contains('medicine'));
    });

    test('handles empty and whitespace strings gracefully', () {
      expect(service.translateToEnglish(''), '');
      expect(service.translateToEnglish('   '), '');
      expect(service.translateToIndonesian(''), '');
    });

    test('translates English back to Indonesian when in dictionary', () {
      expect(service.translateToIndonesian('Hello').toLowerCase(), 'halo');
      expect(service.translateToIndonesian('Coffee').toLowerCase(), 'kopi');
      expect(service.translateToIndonesian('Order coffee').toLowerCase(), 'pesan kopi');
    });

    test('getLocalizedText respects languageCode', () {
      expect(
        service.getLocalizedText('Halo', languageCode: 'en'),
        'Hello',
      );
      expect(
        service.getLocalizedText('Halo', languageCode: 'en-US'),
        'Hello',
      );
      expect(
        service.getLocalizedText('Halo', languageCode: 'id'),
        'Halo',
      );
      expect(
        service.getLocalizedText('Halo', languageCode: 'id-ID'),
        'Halo',
      );
    });
  });
}
