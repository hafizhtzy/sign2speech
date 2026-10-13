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

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] as String,
      originalContent: map['originalContent'] as String,
      translatedContent: map['translatedContent'] as String,
      direction: TranslationDirection.values[map['direction'] as int],
      signLanguageType: map['signLanguageType'] as String? ?? 'BISINDO',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory HistoryItem.fromJson(String source) =>
      HistoryItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
