import 'package:flutter/foundation.dart';

import 'sign_video_entry.dart';

enum SearchMatchType { exact, alias, tokenized, none }

@immutable
class SignSearchResult {
  final String query;
  final List<SignVideoEntry> matchedEntries;
  final SearchMatchType matchType;

  const SignSearchResult({
    required this.query,
    required this.matchedEntries,
    required this.matchType,
  });

  bool get hasMatch => matchedEntries.isNotEmpty;

  @override
  String toString() =>
      'SignSearchResult(query: "$query", matches: ${matchedEntries.length}, type: ${matchType.name})';
}
