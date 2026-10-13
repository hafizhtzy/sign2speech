import 'package:flutter/foundation.dart';

@immutable
class SignVideoEntry {
  final String id;
  final String label;
  final List<String> aliases;
  final String category;
  final String assetPath;
  final String remoteUrl;

  const SignVideoEntry({
    required this.id,
    required this.label,
    required this.aliases,
    required this.category,
    required this.assetPath,
    required this.remoteUrl,
  });

  /// Check whether an input token matches this video entry's label or aliases (case-insensitive)
  bool matches(String query) {
    final clean = query.trim().toLowerCase();
    if (label.toLowerCase() == clean) return true;
    for (final alias in aliases) {
      if (alias.toLowerCase() == clean) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'aliases': aliases,
    'category': category,
    'assetPath': assetPath,
    'remoteUrl': remoteUrl,
  };

  factory SignVideoEntry.fromJson(Map<String, dynamic> json) => SignVideoEntry(
    id: json['id'] as String,
    label: json['label'] as String,
    aliases: List<String>.from(json['aliases'] as List? ?? []),
    category: json['category'] as String,
    assetPath: json['assetPath'] as String,
    remoteUrl: json['remoteUrl'] as String,
  );

  @override
  String toString() => 'SignVideoEntry($label, category: $category)';
}
