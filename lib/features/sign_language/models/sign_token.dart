import 'package:flutter/foundation.dart';

enum SignTokenType { word, letter, space, punctuation }

@immutable
class SignToken {
  final String value;
  final SignTokenType type;
  final DateTime timestamp;

  const SignToken({
    required this.value,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SignToken.fromJson(Map<String, dynamic> json) => SignToken(
    value: json['value'] as String,
    type: SignTokenType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => SignTokenType.word,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  @override
  String toString() => 'SignToken($value, ${type.name})';
}
