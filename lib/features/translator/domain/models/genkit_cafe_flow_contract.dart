// ==============================================================================
// Genkit Cafe Flow Contracts: AI Natural Translation & Cup Spelling
// Sesuai Standar AGENTS.md & GEMINI.md (Aturan 1.D: Alur Pemrosesan AI Cerdas)
// ==============================================================================

/// Result type modelling for Genkit AI Flow operations using Dart 3 sealed class.
sealed class GenkitFlowResult<T> {
  const GenkitFlowResult();
}

/// Success result holding the typed output of the Genkit flow.
final class GenkitFlowSuccess<T> extends GenkitFlowResult<T> {
  final T data;
  final int? latencyMs;

  const GenkitFlowSuccess(this.data, {this.latencyMs});
}

/// Failure result holding error information.
final class GenkitFlowFailure<T> extends GenkitFlowResult<T> {
  final String errorMessage;
  final Object? error;

  const GenkitFlowFailure(this.errorMessage, [this.error]);
}

/// Typed Input Schema for the 'translateSignToNaturalOrder' Genkit Flow.
class SignToCafeOrderInput {
  final List<String> rawSignTokens;
  final String customerNotes;
  final String? detectedCustomerName;

  const SignToCafeOrderInput({
    required this.rawSignTokens,
    this.customerNotes = '',
    this.detectedCustomerName,
  });

  Map<String, dynamic> toJson() => {
    'rawSignTokens': rawSignTokens,
    'customerNotes': customerNotes,
    if (detectedCustomerName != null)
      'detectedCustomerName': detectedCustomerName,
  };

  factory SignToCafeOrderInput.fromJson(Map<String, dynamic> json) {
    return SignToCafeOrderInput(
      rawSignTokens: (json['rawSignTokens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      customerNotes: json['customerNotes']?.toString() ?? '',
      detectedCustomerName: json['detectedCustomerName']?.toString(),
    );
  }
}

/// Typed Output Schema for the 'translateSignToNaturalOrder' Genkit Flow.
class SignToCafeOrderOutput {
  final String naturalSentence;
  final List<String> identifiedMenuItems;
  final String temperature; // 'hot' | 'iced' | 'default'
  final String sweetnessLevel; // 'normal' | 'less_sugar' | 'no_sugar'
  final double confidenceScore;

  const SignToCafeOrderOutput({
    required this.naturalSentence,
    required this.identifiedMenuItems,
    this.temperature = 'default',
    this.sweetnessLevel = 'normal',
    this.confidenceScore = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'naturalSentence': naturalSentence,
    'identifiedMenuItems': identifiedMenuItems,
    'temperature': temperature,
    'sweetnessLevel': sweetnessLevel,
    'confidenceScore': confidenceScore,
  };

  factory SignToCafeOrderOutput.fromJson(Map<String, dynamic> json) {
    return SignToCafeOrderOutput(
      naturalSentence: json['naturalSentence']?.toString() ?? '',
      identifiedMenuItems: (json['identifiedMenuItems'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      temperature: json['temperature']?.toString() ?? 'default',
      sweetnessLevel: json['sweetnessLevel']?.toString() ?? 'normal',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Typed Input Schema for Cup Name Spelling Correction Flow.
class CupNameCorrectionInput {
  final String rawSpelledName;

  const CupNameCorrectionInput({required this.rawSpelledName});

  Map<String, dynamic> toJson() => {'rawSpelledName': rawSpelledName};

  factory CupNameCorrectionInput.fromJson(Map<String, dynamic> json) {
    return CupNameCorrectionInput(
      rawSpelledName: json['rawSpelledName']?.toString() ?? '',
    );
  }
}

/// Typed Output Schema for Cup Name Spelling Correction Flow.
class CupNameCorrectionOutput {
  final String correctedName;
  final bool wasCorrected;
  final double confidence;

  const CupNameCorrectionOutput({
    required this.correctedName,
    required this.wasCorrected,
    this.confidence = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'correctedName': correctedName,
    'wasCorrected': wasCorrected,
    'confidence': confidence,
  };

  factory CupNameCorrectionOutput.fromJson(Map<String, dynamic> json) {
    return CupNameCorrectionOutput(
      correctedName: json['correctedName']?.toString() ?? '',
      wasCorrected: json['wasCorrected'] == true,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
