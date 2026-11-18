import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/sign_language_catalog.dart';
import '../models/sign_search_result.dart';
import '../models/sign_video_entry.dart';
import 'sign_language_asset_registry.dart';
import 'sign_language_cache_service.dart';
import 'sign_language_config.dart';

class SignLanguageRepository {
  SignLanguageCatalog catalog;
  final SignLanguageConfig config;
  final SignLanguageAssetRegistry assetRegistry;
  final SignLanguageCacheService cacheService;

  static SignLanguageRepository? _staticInstance;

  static SignLanguageRepository get instance {
    if (_staticInstance != null) return _staticInstance!;
    if (Get.isRegistered<SignLanguageRepository>()) {
      try {
        return Get.find<SignLanguageRepository>();
      } catch (_) {}
    }
    final repo = SignLanguageRepository(
      catalog: SignLanguageCatalog.defaultCatalog(),
    );
    _staticInstance = repo;
    if (!Get.isRegistered<SignLanguageRepository>()) {
      Get.put<SignLanguageRepository>(repo, permanent: true);
    }
    return repo;
  }

  List<SignVideoEntry> get allCatalogEntries => catalog.entries;

  SignLanguageRepository({
    required this.catalog,
    this.config = const SignLanguageConfig(),
    SignLanguageAssetRegistry? assetRegistry,
    SignLanguageCacheService? cacheService,
  }) : assetRegistry = assetRegistry ?? SignLanguageAssetRegistry(),
       cacheService = cacheService ?? SignLanguageCacheService();

  /// Sinkronisasi katalog dari file asset lokal atau remote endpoint
  Future<void> loadCatalog({bool forceRemote = false}) async {
    try {
      if (forceRemote) {
        catalog = await SignLanguageCatalog.loadFromRemote(
          catalogUrl: SignLanguageConfig.catalogUrl,
          baseUrl: config.baseUrl,
        );
      } else {
        catalog = await SignLanguageCatalog.loadFromAsset(
          baseUrl: config.baseUrl,
        );
      }
      await mergePublishedCloudVideos();
    } catch (e) {
      debugPrint('[SignRepo] Gagal sync katalog: $e');
    }
  }

  /// Fetches ONLY `published` videos from `public.sign_language_videos` and resolves
  /// short-lived Signed URLs from the private `sign-language-videos` bucket.
  /// Draft and archived videos are never exposed to customer catalog playback.
  Future<void> mergePublishedCloudVideos() async {
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      return;
    }

    try {
      final rows = await client
          .from('sign_language_videos')
          .select()
          .eq('publication_status', 'published')
          .order('created_at', ascending: false);

      if (rows.isEmpty) return;

      final merged = List<SignVideoEntry>.from(catalog.entries);
      for (final row in rows) {
        final id = (row['id'] ?? '').toString();
        final gloss = (row['gloss'] ?? row['title'] ?? '').toString().trim();
        final lang =
            (row['language_type'] ?? 'BISINDO').toString().toLowerCase();
        final storageBucket =
            (row['storage_bucket'] ?? AppConstants.signLanguageVideosBucket)
                .toString();
        final storagePath = (row['storage_path'] ?? '').toString();
        if (gloss.isEmpty || storagePath.isEmpty) continue;

        String resolvedRemoteUrl = '';
        try {
          resolvedRemoteUrl = await client.storage
              .from(storageBucket)
              .createSignedUrl(storagePath, 3600);
        } catch (_) {
          continue;
        }

        final rawAliases = row['aliases'];
        final aliases = rawAliases is List
            ? rawAliases.map((e) => e.toString()).toList()
            : const <String>[];

        final entry = SignVideoEntry(
          id: id.isNotEmpty
              ? id
              : '${lang}_${SignVideoEntry.formatSlug(gloss)}',
          label: gloss,
          aliases: aliases,
          category: (row['category'] ?? 'umum').toString(),
          assetPath: '',
          remoteUrl: resolvedRemoteUrl,
          relativePath: storagePath,
          type: 'word',
          source: SignVideoSource.remote,
          signSystem: lang,
        );

        final existingIdx = merged.indexWhere(
          (e) =>
              e.signSystem.toLowerCase() == lang &&
              e.label.toLowerCase() == gloss.toLowerCase(),
        );
        if (existingIdx >= 0) {
          merged[existingIdx] = entry;
        } else {
          merged.add(entry);
        }
      }

      catalog = SignLanguageCatalog(
        entries: merged,
      );
    } catch (_) {
      // Offline / table not migrated yet: keep bundled & cached catalog intact
    }
  }

  /// Clean input query: lowercase, trim, remove punctuation, normalize spaces
  String normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Dynamically constructs a SignVideoEntry matching the consistent Supabase Storage CDN schema:
  /// {supabaseUrl}/storage/v1/object/public/sign-videos/videos/{system}/{slug}_v1.mp4
  SignVideoEntry createDynamicEntry(String word, String signSystem) {
    final system =
        signSystem.toLowerCase().trim() == 'sibi' ? 'sibi' : 'bisindo';
    final slug = SignVideoEntry.formatSlug(word);
    final relPath = 'videos/$system/${slug}_v1.mp4';
    return SignVideoEntry(
      id: '${system}_$slug',
      label: word.trim(),
      aliases: const [],
      category: 'online',
      assetPath: 'assets/sign_language/offline/$system/kalimat/$word.mp4',
      remoteUrl: SignLanguageConfig.resolveVideoUrl(
        relPath,
        baseUrl: config.baseUrl,
      ),
      relativePath: relPath,
      type: 'word',
      signSystem: system,
    );
  }

  /// Memuat daftar video yang tersedia untuk bahasa tertentu dengan status sumber teresolusi.
  Future<List<SignVideoEntry>> getAvailableVideos({
    String language = 'bisindo',
    bool forceRefresh = false,
  }) async {
    final lang = language.toLowerCase().trim();
    final entries = catalog.entries.where((e) {
      final isSibi = e.signSystem.toLowerCase() == 'sibi' ||
          e.id.startsWith('sibi') ||
          e.assetPath.contains('/sibi/') ||
          e.remoteUrl.contains('/sibi/');
      if (lang == 'sibi') return isSibi;
      return !isSibi;
    }).toList();

    final List<SignVideoEntry> resolvedList = [];
    for (final e in entries) {
      final resolved = await resolveVideoSource(e);
      resolvedList.add(resolved);
    }
    return resolvedList;
  }

  /// 4-Tier Hierarchical Search Engine:
  /// 1. Exact Phrase Match (bahasa yang sama)
  /// 2. Synonym / Alias Match (bahasa yang sama)
  /// 3. Tokenized Word-by-Word Sequential Match (bahasa yang sama)
  /// 4. Cross-Language Fallback (bahasa lain jika tidak ada di bahasa pilihan)
  Future<SignSearchResult> searchSign(
    String query, [
    String languageCode = 'bisindo',
  ]) async {
    final clean = normalizeText(query);
    if (clean.isEmpty) {
      return SignSearchResult(
        query: query,
        language: languageCode,
        matchedEntries: const [],
        matchType: SearchMatchType.none,
        isFound: false,
      );
    }

    // 1. Exact Phrase Match (strict: bahasa yang sama saja)
    final exact = catalog.findExact(clean, languageCode);
    if (exact != null) {
      final resolved = await resolveVideoSource(exact);
      return SignSearchResult(
        query: query,
        language: languageCode,
        matchedEntries: [resolved],
        matchType: SearchMatchType.exact,
        exactMatch: resolved,
        candidates: [resolved],
        isFound: true,
      );
    }

    // 2. Alias Match (strict: bahasa yang sama saja)
    final aliasMatch = catalog.findByAlias(clean, languageCode);
    if (aliasMatch != null) {
      final resolved = await resolveVideoSource(aliasMatch);
      return SignSearchResult(
        query: query,
        language: languageCode,
        matchedEntries: [resolved],
        matchType: SearchMatchType.alias,
        exactMatch: resolved,
        candidates: [resolved],
        isFound: true,
      );
    }

    // 3. Multi-word & Tokenized Greedy Match (Maximum Forward Matching)
    // Supports compound phrases (e.g. "pisang goreng", "terima kasih", "kopi susu")
    // as well as single-word vocabulary items.
    final tokens = clean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final List<SignVideoEntry> tokenMatches = [];
    int i = 0;
    const maxNgram = 4; // Longest phrases in sign dictionaries are 3-4 words

    while (i < tokens.length) {
      SignVideoEntry? matchedEntry;
      int matchedWordCount = 1;

      // Try longest subphrase first down to 1 word
      final maxK = (tokens.length - i).clamp(1, maxNgram);
      for (int k = maxK; k >= 1; k--) {
        final phrase = tokens.sublist(i, i + k).join(' ');
        final match = catalog.findBestMatch(phrase, languageCode) ??
            catalog.findBestMatchWithFallback(phrase, languageCode);
        if (match != null) {
          matchedEntry = match;
          matchedWordCount = k;
          break;
        }
      }

      if (matchedEntry != null) {
        tokenMatches.add(matchedEntry);
        i += matchedWordCount;
      } else {
        // Unknown token, advance by 1
        i++;
      }
    }

    if (tokenMatches.isNotEmpty) {
      final resolvedMatches = <SignVideoEntry>[];
      for (final m in tokenMatches) {
        resolvedMatches.add(await resolveVideoSource(m));
      }
      return SignSearchResult(
        query: query,
        language: languageCode,
        matchedEntries: resolvedMatches,
        matchType: SearchMatchType.tokenized,
        exactMatch: resolvedMatches.first,
        candidates: resolvedMatches,
        isFound: true,
      );
    }

    // 4. Cross-Language Fallback (cari di bahasa lain, tapi tampilkan dengan status remote/download)
    final crossLangEntry = catalog.findBestMatchWithFallback(clean, languageCode);
    if (crossLangEntry != null) {
      final resolved = await resolveVideoSource(crossLangEntry);
      return SignSearchResult(
        query: query,
        language: languageCode,
        matchedEntries: [resolved],
        matchType: SearchMatchType.alias, // tetap gunakan alias match type
        exactMatch: resolved,
        candidates: [resolved],
        isFound: true,
        isCrossLanguageFallback: true,
        crossLanguageSystem: crossLangEntry.signSystem,
      );
    }

    return SignSearchResult(
      query: query,
      language: languageCode,
      matchedEntries: const [],
      matchType: SearchMatchType.none,
      isFound: false,
    );
  }


  /// 3-Tier Video Source Resolution:
  /// Tier 1: Bundled APK asset -> returns SignVideoEntry with SignVideoSource.asset
  /// Tier 2: Local storage disk cache -> returns SignVideoEntry with SignVideoSource.localCached
  /// Tier 3: Online video -> returns SignVideoEntry with SignVideoSource.remote (or downloads if autoDownload=true)
  Future<SignVideoEntry> resolveVideoSource(
    SignVideoEntry entry, {
    void Function(double progress)? onProgress,
    bool autoDownload = false,
  }) async {
    // Tier 1: Bundled Asset
    if (entry.assetPath.isNotEmpty &&
        assetRegistry.isAssetBundled(entry.assetPath)) {
      return entry.copyWith(
        source: SignVideoSource.asset,
      );
    }

    // Tier 2: Local Disk Cache
    if (await cacheService.isVideoCached(entry.id)) {
      final file = await cacheService.getCachedVideoFile(entry.id);
      if (await file.exists() && await file.length() > 0) {
        return entry.copyWith(
          source: SignVideoSource.localCached,
          cachedFilePath: file.path,
        );
      }
    }

    // Tier 3: Remote CDN
    if (autoDownload && entry.remoteUrl.isNotEmpty) {
      final downloaded = await downloadVideo(entry, onProgress: onProgress);
      return downloaded;
    }

    return entry.copyWith(
      source: SignVideoSource.remote,
    );
  }

  /// Helper untuk mendapatkan string path aktual video (kompatibilitas widget)
  Future<String> resolveVideoPath(
    SignVideoEntry entry, {
    void Function(double progress)? onProgress,
  }) async {
    final resolved = await resolveVideoSource(
      entry,
      onProgress: onProgress,
      autoDownload: true,
    );
    return resolved.path;
  }

  /// Mengunduh video tunggal dari CDN dan menyimpannya ke cache lokal secara atomik.
  Future<SignVideoEntry> downloadVideo(
    SignVideoEntry entry, {
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    // Jika sudah ada di cache lokal, kembalikan langsung
    if (await cacheService.isVideoCached(entry.id)) {
      final file = await cacheService.getCachedVideoFile(entry.id);
      if (await file.exists() && await file.length() > 0) {
        if (onProgress != null) onProgress(1.0);
        return entry.copyWith(
          source: SignVideoSource.localCached,
          cachedFilePath: file.path,
        );
      }
    }

    final targetFile = await cacheService.downloadVideoAtomic(
      videoId: entry.id,
      remoteUrl: entry.remoteUrl,
      cancelToken: cancelToken,
      onProgress: onProgress,
    );

    if (targetFile != null &&
        await targetFile.exists() &&
        await targetFile.length() > 0) {
      return entry.copyWith(
        source: SignVideoSource.localCached,
        cachedFilePath: targetFile.path,
      );
    }

    return entry.copyWith(source: SignVideoSource.remote);
  }

  /// Menghapus semua file video unduhan dari disk cache.
  Future<int> clearDownloadedVideos() async {
    return await cacheService.clearCache();
  }

  /// Mengunduh seluruh video dalam satu kategori secara batch.
  Future<bool> downloadCategory(
    String category, {
    String language = 'bisindo',
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
  }) async {
    final lang = language.toLowerCase().trim();
    final entries = catalog.getByCategory(category).where((e) {
      if (lang == 'sibi') {
        return e.signSystem.toLowerCase() == 'sibi' ||
            e.id.startsWith('sibi') ||
            e.assetPath.contains('/sibi/');
      }
      return e.signSystem.toLowerCase() == 'bisindo' ||
          (!e.id.startsWith('sibi') && !e.assetPath.contains('/sibi/'));
    }).toList();

    if (entries.isEmpty) return false;

    int completed = 0;
    final total = entries.length;

    for (final entry in entries) {
      if (cancelToken?.isCancelled ?? false) break;
      try {
        await downloadVideo(entry, cancelToken: cancelToken);
      } on SignVideoNotAvailableException catch (e) {
        debugPrint('[SignRepo] Lewati ${entry.id}: $e');
      }
      completed++;
      if (onProgress != null) {
        onProgress(completed / total);
      }
    }
    return true;
  }
}

