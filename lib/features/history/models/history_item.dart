import 'dart:convert';

enum TranslationDirection { signToSpeech, speechToSign }

class HistoryItem {
  final String id;
  final String originalContent;
  final String translatedContent;
  final TranslationDirection direction;
  final String signLanguageType; // 'BISINDO' or 'SIBI'
  final DateTime timestamp;

  const HistoryItem({
    required this.id,
    required this.originalContent,
    required this.translatedContent,
    required this.direction,
    required this.signLanguageType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalContent': originalContent,
      'translatedContent': translatedContent,
      'direction': direction.index,
      'signLanguageType': signLanguageType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// PostgreSQL snake_case serialization for `translations_history` table.
  Map<String, dynamic> toPostgresMap() {
    return {
      'id': id,
      'original_content': originalContent,
      'translated_content': translatedContent,
      'direction': direction.name,
      'sign_language_type': signLanguageType,
      'timestamp': timestamp.toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    final rawDirection = map['direction'];
    TranslationDirection parsedDirection = TranslationDirection.signToSpeech;
    if (rawDirection is int &&
        rawDirection >= 0 &&
        rawDirection < TranslationDirection.values.length) {
      parsedDirection = TranslationDirection.values[rawDirection];
    } else if (rawDirection is String) {
      parsedDirection = TranslationDirection.values.firstWhere(
        (e) => e.name == rawDirection,
        orElse: () => TranslationDirection.signToSpeech,
      );
    }

    final rawTimestamp =
        (map['timestamp'] ?? map['created_at'] ?? map['createdAt'])?.toString();

    return HistoryItem(
      id: (map['id'] ?? '') as String,
      originalContent:
          (map['originalContent'] ?? map['original_content'] ?? '') as String,
      translatedContent:
          (map['translatedContent'] ?? map['translated_content'] ?? '')
              as String,
      direction: parsedDirection,
      signLanguageType: (map['signLanguageType'] ??
              map['sign_language_type'] ??
              'BISINDO') as String,
      timestamp: rawTimestamp != null
          ? (DateTime.tryParse(rawTimestamp) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoryItem.fromJson(String source) =>
      HistoryItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
