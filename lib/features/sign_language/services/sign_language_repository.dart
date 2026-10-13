import 'dart:async';

import '../models/sign_language_catalog.dart';
import '../models/sign_search_result.dart';
import '../models/sign_video_entry.dart';
import 'sign_language_asset_registry.dart';
import 'sign_language_cache_service.dart';
import 'sign_language_config.dart';

class SignLanguageRepository {
  final SignLanguageCatalog catalog;
  final SignLanguageConfig config;
  final SignLanguageAssetRegistry assetRegistry;
  final SignLanguageCacheService cacheService;

  List<SignVideoEntry> get allCatalogEntries => catalog.entries;

  SignLanguageRepository({
    required this.catalog,
    this.config = const SignLanguageConfig(),
    SignLanguageAssetRegistry? assetRegistry,
    SignLanguageCacheService? cacheService,
  }) : assetRegistry = assetRegistry ?? SignLanguageAssetRegistry(),
       cacheService = cacheService ?? SignLanguageCacheService();

  /// Clean input query: lowercase, trim, remove punctuation, normalize spaces
  String normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 3-Tier Hierarchical Search Engine:
  /// 1. Exact Phrase Match
  /// 2. Synonym / Alias Match
  /// 3. Tokenized Word-by-Word Sequential Match
  Future<SignSearchResult> searchSign(String query, String languageCode) async {
    final clean = normalizeText(query);
    if (clean.isEmpty) {
      return SignSearchResult(
        query: query,
        matchedEntries: const [],
        matchType: SearchMatchType.none,
      );
    }

    // 1. Exact Phrase Match
    final exact = catalog.findExact(clean);
    if (exact != null) {
      return SignSearchResult(
        query: query,
        matchedEntries: [exact],
        matchType: SearchMatchType.exact,
      );
    }

    // 2. Alias Match
    final aliasMatch = catalog.findByAlias(clean);
    if (aliasMatch != null) {
      return SignSearchResult(
        query: query,
        matchedEntries: [aliasMatch],
        matchType: SearchMatchType.alias,
      );
    }

    // 3. Tokenized Match
    final tokens = clean.split(' ');
    final List<SignVideoEntry> tokenMatches = [];
    for (final token in tokens) {
      if (token.isEmpty) continue;
      final match = catalog.findBestMatch(token);
      if (match != null) {
        tokenMatches.add(match);
      }
    }

    if (tokenMatches.isNotEmpty) {
      return SignSearchResult(
        query: query,
        matchedEntries: tokenMatches,
        matchType: SearchMatchType.tokenized,
      );
    }

    return SignSearchResult(
      query: query,
      matchedEntries: const [],
      matchType: SearchMatchType.none,
    );
  }

  /// 3-Tier Video Source Resolution:
  /// Tier 1: Bundled APK asset -> returns asset path directly
  /// Tier 2: Local storage disk cache -> returns local file path
  /// Tier 3: Remote CDN Firebase hosting -> returns remote URL + triggers background caching
  Future<String> resolveVideoSource(SignVideoEntry entry) async {
    // Tier 1: Check bundled asset
    if (assetRegistry.isAssetBundled(entry.assetPath)) {
      return entry.assetPath;
    }

    // Tier 2: Check local cache
    if (await cacheService.isVideoCached(entry.id)) {
      final file = await cacheService.getCachedVideoFile(entry.id);
      return file.path;
    }

    // Tier 3: Fallback to remote CDN URL with asynchronous cache-on-play
    final remote = entry.remoteUrl;
    unawaited(_cacheVideoInBackground(entry));
    return remote;
  }

  Future<void> _cacheVideoInBackground(SignVideoEntry entry) async {
    try {
      await cacheService.downloadVideoAtomic(
        videoId: entry.id,
        remoteUrl: entry.remoteUrl,
      );
    } catch (_) {
      // Background cache failure should not disrupt playback
    }
  }

  /// Downloads all videos belonging to a category
  Future<bool> downloadCategory(
    String categoryId, {
    void Function(double progress)? onProgress,
  }) async {
    final entries = catalog.getByCategory(categoryId);
    if (entries.isEmpty) return false;

    int completed = 0;
    for (final entry in entries) {
      await cacheService.downloadVideoAtomic(
        videoId: entry.id,
        remoteUrl: entry.remoteUrl,
      );
      completed++;
      if (onProgress != null) {
        onProgress(completed / entries.length);
      }
    }
    return true;
  }
}
