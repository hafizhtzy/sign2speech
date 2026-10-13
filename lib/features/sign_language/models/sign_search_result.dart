import 'package:flutter/foundation.dart';

import 'sign_video_entry.dart';

enum SearchMatchType { exact, alias, tokenized, none }

@immutable
class SignSearchResult {
  final String query;
  final String language;
  final List<SignVideoEntry> matchedEntries;
  final SearchMatchType matchType;
  final SignVideoEntry? exactMatch;
  final List<SignVideoEntry> candidates;
  final bool isFound;

  /// Apakah hasil ini berasal dari bahasa lain (fallback lintas bahasa)?
  final bool isCrossLanguageFallback;

  /// Bahasa asli dari hasil fallback (misalnya 'sibi' jika user mencari di 'bisindo')
  final String? crossLanguageSystem;

  SignSearchResult({
    required this.query,
    this.language = 'bisindo',
    List<SignVideoEntry>? matchedEntries,
    this.matchType = SearchMatchType.none,
    SignVideoEntry? exactMatch,
    List<SignVideoEntry>? candidates,
    bool? isFound,
    this.isCrossLanguageFallback = false,
    this.crossLanguageSystem,
  })  : matchedEntries = matchedEntries ??
            (candidates ?? (exactMatch != null ? [exactMatch] : const [])),
        exactMatch = exactMatch ??
            (matchedEntries != null && matchedEntries.isNotEmpty
                ? matchedEntries.first
                : null),
        candidates = candidates ?? (matchedEntries ?? const []),
        isFound = isFound ??
            (matchedEntries != null && matchedEntries.isNotEmpty ||
                exactMatch != null);

  const SignSearchResult.empty({
    this.query = '',
    this.language = 'bisindo',
  })  : matchedEntries = const [],
        matchType = SearchMatchType.none,
        exactMatch = null,
        candidates = const [],
        isFound = false,
        isCrossLanguageFallback = false,
        crossLanguageSystem = null;

  bool get hasMatch => isFound || matchedEntries.isNotEmpty;

  @override
  String toString() =>
      'SignSearchResult(query: "$query", matches: ${matchedEntries.length}, type: ${matchType.name}, crossLang: $isCrossLanguageFallback)';
}
