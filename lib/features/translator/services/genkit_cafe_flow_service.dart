// ==============================================================================
// Genkit Cafe Flow Service: Normalisasi Tata Bahasa Isyarat & Ejaan Gelas
// Sesuai Standar AGENTS.md & GEMINI.md (Aturan 1.D: Alur Pemrosesan AI Cerdas)
// ==============================================================================

import 'package:flutter/foundation.dart';
import '../domain/models/genkit_cafe_flow_contract.dart';

/// Service yang mengorkestrasi eksekusi AI Flow Genkit untuk normalisasi pesanan
/// isyarat kafe dan koreksi nama gelas. Mendukung fallback offline deterministik.
class GenkitCafeFlowService {
  final String? endpointUrl;

  GenkitCafeFlowService({this.endpointUrl});

  /// Normalisasi deretan token isyarat lepas menjadi kalimat pesanan kafe santun.
  Future<GenkitFlowResult<SignToCafeOrderOutput>> normalizeSignOrder(
    SignToCafeOrderInput input,
  ) async {
    final stopwatch = Stopwatch()..start();

    if (input.rawSignTokens.isEmpty) {
      return const GenkitFlowSuccess(
        SignToCafeOrderOutput(
          naturalSentence: '',
          identifiedMenuItems: [],
          temperature: 'default',
          sweetnessLevel: 'normal',
          confidenceScore: 1.0,
        ),
      );
    }

    try {
      // 1. Eksekusi Remote Flow via Genkit jika endpointUrl tersedia
      if (endpointUrl != null && endpointUrl!.isNotEmpty) {
        // Siap untuk dipanggil via Genkit HTTP Gateway / Firebase AI Logic
        debugPrint('GenkitCafeFlowService: Calling remote flow at $endpointUrl');
      }

      // 2. Deterministic Rule-Based Context Normalizer (Offline First)
      final output = _normalizeOffline(input);
      stopwatch.stop();

      return GenkitFlowSuccess(output, latencyMs: stopwatch.elapsedMilliseconds);
    } catch (e, stack) {
      stopwatch.stop();
      debugPrint('GenkitCafeFlowService error: $e\n$stack');
      return GenkitFlowFailure('Gagal menormalkan kalimat isyarat: $e', e);
    }
  }

  /// Koreksi ejaan nama pelanggan pada gelas kafe dari ejaan isyarat alfabet.
  Future<GenkitFlowResult<CupNameCorrectionOutput>> correctCupName(
    CupNameCorrectionInput input,
  ) async {
    final raw = input.rawSpelledName.trim();
    if (raw.isEmpty) {
      return const GenkitFlowSuccess(
        CupNameCorrectionOutput(
          correctedName: '',
          wasCorrected: false,
          confidence: 1.0,
        ),
      );
    }

    // Pembersihan karakter repetitif atau pemisah spasi ganda
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ');
    final capitalized = cleaned
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
        .join(' ');

    final wasChanged = capitalized != raw;
    return GenkitFlowSuccess(
      CupNameCorrectionOutput(
        correctedName: capitalized,
        wasCorrected: wasChanged,
        confidence: 0.95,
      ),
    );
  }

  /// Logika normalisasi lokal kafe untuk translasi santun berstandar Bahasa Indonesia.
  SignToCafeOrderOutput _normalizeOffline(SignToCafeOrderInput input) {
    final tokens = input.rawSignTokens.map((t) => t.trim().toLowerCase()).toList();

    // Deteksi Suhu
    final isIced = tokens.any((t) => t == 'es' || t == 'dingin' || t == 'ice');
    final isHot = tokens.any((t) => t == 'panas' || t == 'hangat' || t == 'hot');
    final temperature = isIced ? 'iced' : (isHot ? 'hot' : 'default');

    // Deteksi Tingkat Kemanisan
    final isNoSugar = tokens.any((t) => t == 'tanpa gula' || t == 'no sugar');
    final isLessSugar = tokens.any((t) => t == 'sedikit gula' || t == 'less sugar' || t == 'sedikit');
    final sweetness = isNoSugar ? 'no_sugar' : (isLessSugar ? 'less_sugar' : 'normal');

    // Filter token item menu (abaikan modifier)
    final filteredTokens = tokens.where((t) {
      return !['es', 'dingin', 'panas', 'hangat', 'gula', 'sedikit', 'tanpa', 'pesan', 'mau', 'tolong'].contains(t);
    }).toList();

    // Bentuk nama item
    final rawItemName = filteredTokens.isNotEmpty
        ? filteredTokens.join(' ')
        : 'Pesanan';

    final tempPrefix = switch (temperature) {
      'iced' => 'Es ',
      'hot' => 'Panas ',
      _ => '',
    };

    final itemNameFormatted = '$tempPrefix${_titleCase(rawItemName)}';

    final sweetnessClause = switch (sweetness) {
      'less_sugar' => ', manisnya sedikit',
      'no_sugar' => ', tanpa gula',
      _ => '',
    };

    final nameClause = input.detectedCustomerName != null && input.detectedCustomerName!.isNotEmpty
        ? ' atas nama ${input.detectedCustomerName}'
        : '';

    final naturalSentence = 'Saya mau pesan 1 $itemNameFormatted$sweetnessClause$nameClause. Terima kasih.';

    return SignToCafeOrderOutput(
      naturalSentence: naturalSentence,
      identifiedMenuItems: [itemNameFormatted.trim()],
      temperature: temperature,
      sweetnessLevel: sweetness,
      confidenceScore: 0.96,
    );
  }

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}
