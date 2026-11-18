import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/translator/domain/models/genkit_cafe_flow_contract.dart';
import 'package:speech2sign/features/translator/services/genkit_cafe_flow_service.dart';

void main() {
  group('Genkit Cafe Flow Contracts & Serialization Tests', () {
    test('SignToCafeOrderInput serializes and deserializes correctly', () {
      const input = SignToCafeOrderInput(
        rawSignTokens: ['kopi', 'susu', 'dingin'],
        customerNotes: 'Bawa pulang',
        detectedCustomerName: 'Fadli',
      );

      final json = input.toJson();
      expect(json['rawSignTokens'], ['kopi', 'susu', 'dingin']);
      expect(json['customerNotes'], 'Bawa pulang');
      expect(json['detectedCustomerName'], 'Fadli');

      final fromJson = SignToCafeOrderInput.fromJson(json);
      expect(fromJson.rawSignTokens, input.rawSignTokens);
      expect(fromJson.customerNotes, input.customerNotes);
      expect(fromJson.detectedCustomerName, input.detectedCustomerName);
    });

    test('SignToCafeOrderOutput serializes and deserializes correctly', () {
      const output = SignToCafeOrderOutput(
        naturalSentence: 'Saya mau pesan 1 Es Kopi Susu. Terima kasih.',
        identifiedMenuItems: ['Es Kopi Susu'],
        temperature: 'iced',
        sweetnessLevel: 'normal',
        confidenceScore: 0.98,
      );

      final json = output.toJson();
      expect(json['temperature'], 'iced');
      expect(json['sweetnessLevel'], 'normal');
      expect(json['confidenceScore'], 0.98);

      final fromJson = SignToCafeOrderOutput.fromJson(json);
      expect(fromJson.naturalSentence, output.naturalSentence);
      expect(fromJson.identifiedMenuItems, output.identifiedMenuItems);
      expect(fromJson.temperature, output.temperature);
      expect(fromJson.confidenceScore, 0.98);
    });

    test('CupNameCorrectionInput & Output roundtrip', () {
      const input = CupNameCorrectionInput(rawSpelledName: 'fadli ahmad');
      final inputJson = input.toJson();
      expect(CupNameCorrectionInput.fromJson(inputJson).rawSpelledName, 'fadli ahmad');

      const output = CupNameCorrectionOutput(
        correctedName: 'Fadli Ahmad',
        wasCorrected: true,
        confidence: 0.95,
      );
      final outputJson = output.toJson();
      final outputObj = CupNameCorrectionOutput.fromJson(outputJson);
      expect(outputObj.correctedName, 'Fadli Ahmad');
      expect(outputObj.wasCorrected, isTrue);
    });
  });

  group('GenkitCafeFlowService Offline Execution Tests', () {
    late GenkitCafeFlowService service;

    setUp(() {
      service = GenkitCafeFlowService();
    });

    test('normalizeSignOrder returns empty output for empty input tokens', () async {
      const input = SignToCafeOrderInput(rawSignTokens: []);
      final result = await service.normalizeSignOrder(input);

      expect(result, isA<GenkitFlowSuccess<SignToCafeOrderOutput>>());
      final success = result as GenkitFlowSuccess<SignToCafeOrderOutput>;
      expect(success.data.naturalSentence, isEmpty);
    });

    test('normalizeSignOrder constructs polite natural cafe sentence with temperature and sweetness', () async {
      const input = SignToCafeOrderInput(
        rawSignTokens: ['kopi', 'susu', 'dingin', 'sedikit', 'gula'],
        detectedCustomerName: 'Budi',
      );

      final result = await service.normalizeSignOrder(input);

      final message = switch (result) {
        GenkitFlowSuccess(:final data) => data.naturalSentence,
        GenkitFlowFailure(:final errorMessage) => 'Error: $errorMessage',
      };

      expect(message, contains('Es Kopi Susu'));
      expect(message, contains('manisnya sedikit'));
      expect(message, contains('atas nama Budi'));
      expect(message, contains('Terima kasih.'));
    });

    test('correctCupName formats multi-word customer names into Title Case', () async {
      const input = CupNameCorrectionInput(rawSpelledName: 'siti  rahma ');
      final result = await service.correctCupName(input);

      expect(result, isA<GenkitFlowSuccess<CupNameCorrectionOutput>>());
      final success = result as GenkitFlowSuccess<CupNameCorrectionOutput>;
      expect(success.data.correctedName, 'Siti Rahma');
      expect(success.data.wasCorrected, isTrue);
    });
  });
}
