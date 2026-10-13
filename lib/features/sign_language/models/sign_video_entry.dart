import 'package:flutter/foundation.dart';

enum SignVideoSource {
  asset,
  localCached,
  remote,
}

@immutable
class SignVideoEntry {
  final String id;
  final String label;
  final List<String> aliases;
  final String category;
  final String assetPath;
  final String remoteUrl;
  final SignVideoSource source;
  final String? cachedFilePath;
  final String signSystem;

  const SignVideoEntry({
    required this.id,
    required this.label,
    required this.aliases,
    required this.category,
    required this.assetPath,
    required this.remoteUrl,
    this.source = SignVideoSource.remote,
    this.cachedFilePath,
    this.signSystem = 'bisindo',
  });

  /// Path pemutaran aktual (lokal cache jika ada, atau bundled asset, atau remote URL)
  String get path {
    if (source == SignVideoSource.localCached &&
        cachedFilePath != null &&
        cachedFilePath!.isNotEmpty) {
      return cachedFilePath!;
    }
    if (source == SignVideoSource.asset && assetPath.isNotEmpty) {
      return assetPath;
    }
    if (cachedFilePath != null && cachedFilePath!.isNotEmpty) {
      return cachedFilePath!;
    }
    if (assetPath.isNotEmpty) {
      return assetPath;
    }
    return remoteUrl;
  }

  bool get isLocal =>
      source == SignVideoSource.asset || source == SignVideoSource.localCached;

  /// Formats word slug consistently: lowercase with underscores (e.g. "Terima Kasih" -> "terima_kasih")
  static String formatSlug(String word) {
    return word
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Standard remote CDN video URL convention:
  /// https://hajicare-sign.web.app/videos/{system}/{slug}_v1.mp4
  static String buildCdnUrl({
    required String word,
    required String signSystem,
    String baseUrl = 'https://hajicare-sign.web.app',
  }) {
    final system =
        signSystem.toLowerCase().trim() == 'sibi' ? 'sibi' : 'bisindo';
    final slug = formatSlug(word);
    return '$baseUrl/videos/$system/${slug}_v1.mp4';
  }

  /// Check whether an input token matches this video entry's label or aliases (case-insensitive)
  bool matches(String query) {
    final clean = query.trim().toLowerCase();
    if (label.toLowerCase() == clean) return true;
    for (final alias in aliases) {
      if (alias.toLowerCase() == clean) return true;
    }
    return false;
  }

  SignVideoEntry copyWith({
    String? id,
    String? label,
    List<String>? aliases,
    String? category,
    String? assetPath,
    String? remoteUrl,
    SignVideoSource? source,
    String? cachedFilePath,
    String? signSystem,
  }) {
    return SignVideoEntry(
      id: id ?? this.id,
      label: label ?? this.label,
      aliases: aliases ?? this.aliases,
      category: category ?? this.category,
      assetPath: assetPath ?? this.assetPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      source: source ?? this.source,
      cachedFilePath: cachedFilePath ?? this.cachedFilePath,
      signSystem: signSystem ?? this.signSystem,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'aliases': aliases,
    'category': category,
    'assetPath': assetPath,
    'remoteUrl': remoteUrl,
    'source': source.name,
    'cachedFilePath': cachedFilePath,
    'signSystem': signSystem,
  };

  factory SignVideoEntry.fromJson(Map<String, dynamic> json) => SignVideoEntry(
    id: json['id'] as String,
    label: json['label'] as String,
    aliases: List<String>.from(json['aliases'] as List? ?? []),
    category: json['category'] as String,
    assetPath: json['assetPath'] as String? ?? '',
    remoteUrl: json['remoteUrl'] as String? ?? '',
    source: SignVideoSource.values.firstWhere(
      (e) => e.name == json['source'],
      orElse: () => SignVideoSource.remote,
    ),
    cachedFilePath: json['cachedFilePath'] as String?,
    signSystem: json['signSystem'] as String? ?? 'bisindo',
  );

  @override
  String toString() =>
      'SignVideoEntry($label, system: $signSystem, source: ${source.name})';
}
