import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../services/sign_language_config.dart';
import 'sign_video_entry.dart';

@immutable
class SignLanguageCatalog {
  final List<SignVideoEntry> entries;

  const SignLanguageCatalog({required this.entries});

  /// Mencari kecocokan tepat berdasarkan label.
  /// Jika [preferredSystem] ditentukan, HANYA mencari di bahasa tersebut.
  /// Untuk fallback lintas bahasa, gunakan [findExactWithFallback].
  SignVideoEntry? findExact(String query, [String? preferredSystem]) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final entry in entries) {
      if (entry.label.trim().toLowerCase() == clean) {
        if (preferredSystem == null ||
            entry.signSystem.toLowerCase() == preferredSystem.toLowerCase()) {
          return entry;
        }
      }
    }
    return null;
  }

  /// Mencari kecocokan tepat dengan fallback lintas bahasa.
  SignVideoEntry? findExactWithFallback(
    String query, [
    String? preferredSystem,
  ]) {
    final preferred = findExact(query, preferredSystem);
    if (preferred != null) return preferred;
    if (preferredSystem != null) return findExact(query, null);
    return null;
  }

  /// Mencari kecocokan berdasarkan alias/sinonim.
  SignVideoEntry? findByAlias(String query, [String? preferredSystem]) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final entry in entries) {
      for (final alias in entry.aliases) {
        if (alias.trim().toLowerCase() == clean) {
          if (preferredSystem == null ||
              entry.signSystem.toLowerCase() == preferredSystem.toLowerCase()) {
            return entry;
          }
          break;
        }
      }
    }
    return null;
  }

  /// Mencari kecocokan alias dengan fallback lintas bahasa.
  SignVideoEntry? findByAliasWithFallback(
    String query, [
    String? preferredSystem,
  ]) {
    final preferred = findByAlias(query, preferredSystem);
    if (preferred != null) return preferred;
    if (preferredSystem != null) return findByAlias(query, null);
    return null;
  }

  /// Mencari kecocokan terbaik (exact -> alias) di bahasa yang sama saja.
  SignVideoEntry? findBestMatch(String query, [String? preferredSystem]) {
    return findExact(query, preferredSystem) ??
        findByAlias(query, preferredSystem);
  }

  /// Mencari kecocokan terbaik dengan fallback lintas bahasa.
  SignVideoEntry? findBestMatchWithFallback(
    String query, [
    String? preferredSystem,
  ]) {
    return findExactWithFallback(query, preferredSystem) ??
        findByAliasWithFallback(query, preferredSystem);
  }

  List<SignVideoEntry> getByCategory(String category) {
    final clean = category.trim().toLowerCase();
    return entries.where((e) => e.category.toLowerCase() == clean).toList();
  }

  /// Pemetaan sinonim tambahan untuk kecocokan percakapan natural
  static const Map<String, List<String>> synonymExtensions = {
    'bisindo_baik': ['bagus', 'oke', 'mantap'],
    'sibi_obat': ['resep', 'farmasi', 'pil'],
    'sibi_bantu': ['tolong', 'bantuan'],
    'bisindo_terima_kasih': ['makasih', 'nuhun', 'thank you', 'trims', 'matur nuwun'],
    'bisindo_halo': ['hai', 'hei', 'hallo'],
    'bisindo_air': ['air putih', 'aqua', 'minum air'],
    'bisindo_apa': ['apakah', 'ada apa', 'apaan'],
    'bisindo_apa_kabar': ['gimana kabar', 'bagaimana kabar', 'kabarmu'],
    'bisindo_dimana': ['di mana', 'ke mana'],
    'bisindo_tuli': ['tuna rungu', 'teman tuli', 'deaf'],
    'bisindo_coklat': ['cokelat', 'chocolate'],
    'bisindo_dingin': ['es', 'ice'],
    'bisindo_sama_sama': ['sama sama', 'kembali'],
    'bisindo_saya': ['aku', 'gue'],
    'bisindo_kamu': ['anda', 'engkau', 'lu'],
  };

  /// Pemetaan internal aset offline bawaan APK (Tier 1)
  static const Map<String, String> offlineAssetMap = {
    'bisindo_a': 'assets/sign_language/offline/bisindo/alfabet/A.mp4',
    'bisindo_b': 'assets/sign_language/offline/bisindo/alfabet/B.mp4',
    'bisindo_c': 'assets/sign_language/offline/bisindo/alfabet/C.mp4',
    'bisindo_d': 'assets/sign_language/offline/bisindo/alfabet/D.mp4',
    'bisindo_e': 'assets/sign_language/offline/bisindo/alfabet/E.mp4',
    'bisindo_dia': 'assets/sign_language/offline/bisindo/alfabet/Dia.mp4',
    'bisindo_air': 'assets/sign_language/offline/bisindo/kalimat/Air.mp4',
    'bisindo_apa': 'assets/sign_language/offline/bisindo/kalimat/Apa.mp4',
    'bisindo_apa_kabar': 'assets/sign_language/offline/bisindo/kalimat/Apa_Kabar.mp4',
    'bisindo_dimana': 'assets/sign_language/offline/bisindo/kalimat/Dimana.mp4',
    'bisindo_halo': 'assets/sign_language/offline/bisindo/kalimat/Halo.mp4',
    'bisindo_kopi': 'assets/sign_language/offline/bisindo/kalimat/Kopi.mp4',
    'bisindo_mandi': 'assets/sign_language/offline/bisindo/kalimat/Mandi.mp4',
    'bisindo_minum': 'assets/sign_language/offline/bisindo/kalimat/Minum.mp4',
    'bisindo_terima_kasih': 'assets/sign_language/offline/bisindo/kalimat/Terima_Kasih.mp4',
    'bisindo_tuli': 'assets/sign_language/offline/bisindo/kalimat/Tuli.mp4',
    'sibi_aku': 'assets/sign_language/offline/sibi/kalimat/Aku.mp4',
    'sibi_bantu': 'assets/sign_language/offline/sibi/kalimat/bantu.mp4',
    'sibi_dia': 'assets/sign_language/offline/sibi/kalimat/Dia.mp4',
    'sibi_haus': 'assets/sign_language/offline/sibi/kalimat/Haus.mp4',
    'sibi_kami': 'assets/sign_language/offline/sibi/kalimat/Kami.mp4',
    'sibi_kamu': 'assets/sign_language/offline/sibi/kalimat/Kamu.mp4',
    'sibi_lapar': 'assets/sign_language/offline/sibi/kalimat/Lapar.mp4',
    'sibi_lelah': 'assets/sign_language/offline/sibi/kalimat/Lelah.mp4',
    'sibi_makan': 'assets/sign_language/offline/sibi/kalimat/Makan.mp4',
    'sibi_masjid': 'assets/sign_language/offline/sibi/kalimat/masjid.mp4',
    'sibi_minum': 'assets/sign_language/offline/sibi/kalimat/Minum.mp4',
    'sibi_sakit': 'assets/sign_language/offline/sibi/kalimat/Sakit.mp4',
  };

  /// Parser resmi untuk file JSON katalog (catalog.json)
  factory SignLanguageCatalog.fromJson(
    Map<String, dynamic> json, {
    String baseUrl = SignLanguageConfig.defaultBaseUrl,
  }) {
    final rawVideos = json['videos'] as List? ?? [];
    final List<SignVideoEntry> parsedEntries = [];

    for (final raw in rawVideos) {
      if (raw is! Map<String, dynamic>) continue;
      final parsed = SignVideoEntry.fromJson(raw, baseUrl: baseUrl);
      final assetPath = parsed.assetPath.isNotEmpty
          ? parsed.assetPath
          : (offlineAssetMap[parsed.id] ?? '');

      // Gabungkan sinonim tambahan untuk kueri ucapan yang variatif
      final extensions = synonymExtensions[parsed.id] ?? const [];
      final mergedAliases = {...parsed.aliases, ...extensions}.toList();

      final entryWithExtras = parsed.copyWith(
        assetPath: assetPath.isNotEmpty ? assetPath : parsed.assetPath,
        aliases: mergedAliases,
      );

      parsedEntries.add(entryWithExtras);
    }

    return SignLanguageCatalog(entries: parsedEntries);
  }

  /// Memuat katalog secara asinkron dari bundled asset lokal
  static Future<SignLanguageCatalog> loadFromAsset({
    String assetPath = AppConstants.signCatalogAssetPath,
    String baseUrl = SignLanguageConfig.defaultBaseUrl,
  }) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return SignLanguageCatalog.fromJson(data, baseUrl: baseUrl);
    } catch (e) {
      debugPrint('[SignCatalog] Fallback ke defaultCatalog: $e');
      return SignLanguageCatalog.defaultCatalog(baseUrl: baseUrl);
    }
  }

  /// Mengunduh dan memuat katalog secara asinkron dari remote CDN
  static Future<SignLanguageCatalog> loadFromRemote({
    String catalogUrl = SignLanguageConfig.catalogUrl,
    String baseUrl = SignLanguageConfig.defaultBaseUrl,
    Dio? dioClient,
  }) async {
    try {
      final dio = dioClient ?? Dio(BaseOptions(
        connectTimeout: SignLanguageConfig.connectTimeout,
        receiveTimeout: SignLanguageConfig.receiveTimeout,
      ));
      final response = await dio.get<Map<String, dynamic>>(catalogUrl);
      if (response.data != null) {
        return SignLanguageCatalog.fromJson(response.data!, baseUrl: baseUrl);
      }
    } catch (e) {
      debugPrint('[SignCatalog] Gagal fetch remote catalog: $e');
    }
    return loadFromAsset(baseUrl: baseUrl);
  }

  /// Default predefined catalog dengan base URL Supabase Storage `sign-videos`
  factory SignLanguageCatalog.defaultCatalog({
    String baseUrl = SignLanguageConfig.defaultBaseUrl,
  }) {
    final rawList = <SignVideoEntry>[
      SignVideoEntry(
        id: 'bisindo_halo',
        label: 'Halo',
        aliases: const ['hai', 'hei', 'hallo'],
        category: 'salam',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Halo.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/halo_v1.mp4',
        relativePath: 'videos/bisindo/halo_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_terima_kasih',
        label: 'Terima Kasih',
        aliases: const ['makasih', 'nuhun', 'thank you', 'trims', 'matur nuwun'],
        category: 'salam',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Terima_Kasih.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/terima_kasih_v1.mp4',
        relativePath: 'videos/bisindo/terima_kasih_v1.mp4',
        type: 'phrase',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_air',
        label: 'Air',
        aliases: const ['air putih', 'aqua', 'minum air'],
        category: 'harian',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Air.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/air_v1.mp4',
        relativePath: 'videos/bisindo/air_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_apa',
        label: 'Apa',
        aliases: const ['apakah', 'ada apa', 'apaan'],
        category: 'question',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Apa.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/apa_v1.mp4',
        relativePath: 'videos/bisindo/apa_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_apa_kabar',
        label: 'Apa Kabar',
        aliases: const ['gimana kabar', 'bagaimana kabar', 'kabarmu'],
        category: 'salam',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Apa_Kabar.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/apa_kabar_v1.mp4',
        relativePath: 'videos/bisindo/apa_kabar_v1.mp4',
        type: 'phrase',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_dimana',
        label: 'Dimana',
        aliases: const ['di mana', 'ke mana'],
        category: 'question',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Dimana.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/dimana_v1.mp4',
        relativePath: 'videos/bisindo/dimana_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kopi',
        label: 'Kopi',
        aliases: const ['ngopi', 'coffee'],
        category: 'food_beverage',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Kopi.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/kopi_v1.mp4',
        relativePath: 'videos/bisindo/kopi_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_mandi',
        label: 'Mandi',
        aliases: const ['membersihkan diri'],
        category: 'activity',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Mandi.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/mandi_v1.mp4',
        relativePath: 'videos/bisindo/mandi_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_minum',
        label: 'Minum',
        aliases: const ['minuman', 'meminum'],
        category: 'food_beverage',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Minum.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/minum_v1.mp4',
        relativePath: 'videos/bisindo/minum_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_tuli',
        label: 'Tuli',
        aliases: const ['tuna rungu', 'teman tuli', 'deaf'],
        category: 'sosial',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Tuli.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/tuli_v1.mp4',
        relativePath: 'videos/bisindo/tuli_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_a',
        label: 'A',
        aliases: const ['huruf a'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/A.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/a_v1.mp4',
        relativePath: 'videos/bisindo/a_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_b',
        label: 'B',
        aliases: const ['huruf b'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/B.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/b_v1.mp4',
        relativePath: 'videos/bisindo/b_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_c',
        label: 'C',
        aliases: const ['huruf c'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/C.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/c_v1.mp4',
        relativePath: 'videos/bisindo/c_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_d',
        label: 'D',
        aliases: const ['huruf d'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/D.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/d_v1.mp4',
        relativePath: 'videos/bisindo/d_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_e',
        label: 'E',
        aliases: const ['huruf e'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/E.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/e_v1.mp4',
        relativePath: 'videos/bisindo/e_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_dia',
        label: 'Dia',
        aliases: const ['ia', 'beliau'],
        category: 'pronoun',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/Dia.mp4',
        remoteUrl: '$baseUrl/videos/bisindo/dia_v1.mp4',
        relativePath: 'videos/bisindo/dia_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'sibi_aku',
        label: 'Aku',
        aliases: const ['saya', 'gue'],
        category: 'pronoun',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Aku.mp4',
        remoteUrl: '$baseUrl/videos/sibi/aku_v1.mp4',
        relativePath: 'videos/sibi/aku_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_bantu',
        label: 'Bantu',
        aliases: const ['tolong', 'bantuan'],
        category: 'courtesy',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/bantu.mp4',
        remoteUrl: '$baseUrl/videos/sibi/bantu_v1.mp4',
        relativePath: 'videos/sibi/bantu_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_dia',
        label: 'Dia',
        aliases: const ['ia', 'beliau'],
        category: 'pronoun',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Dia.mp4',
        remoteUrl: '$baseUrl/videos/sibi/dia_v1.mp4',
        relativePath: 'videos/sibi/dia_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_haus',
        label: 'Haus',
        aliases: const ['dahaga'],
        category: 'health',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Haus.mp4',
        remoteUrl: '$baseUrl/videos/sibi/haus_v1.mp4',
        relativePath: 'videos/sibi/haus_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_kami',
        label: 'Kami',
        aliases: const ['kita'],
        category: 'pronoun',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Kami.mp4',
        remoteUrl: '$baseUrl/videos/sibi/kami_v1.mp4',
        relativePath: 'videos/sibi/kami_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_kamu',
        label: 'Kamu',
        aliases: const ['anda', 'engkau', 'lu'],
        category: 'pronoun',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Kamu.mp4',
        remoteUrl: '$baseUrl/videos/sibi/kamu_v1.mp4',
        relativePath: 'videos/sibi/kamu_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_lapar',
        label: 'Lapar',
        aliases: const ['kelaparan'],
        category: 'health',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Lapar.mp4',
        remoteUrl: '$baseUrl/videos/sibi/lapar_v1.mp4',
        relativePath: 'videos/sibi/lapar_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_lelah',
        label: 'Lelah',
        aliases: const ['capek', 'letih'],
        category: 'health',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Lelah.mp4',
        remoteUrl: '$baseUrl/videos/sibi/lelah_v1.mp4',
        relativePath: 'videos/sibi/lelah_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_makan',
        label: 'Makan',
        aliases: const ['santap', 'makanan'],
        category: 'activity',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Makan.mp4',
        remoteUrl: '$baseUrl/videos/sibi/makan_v1.mp4',
        relativePath: 'videos/sibi/makan_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_masjid',
        label: 'Masjid',
        aliases: const ['musholla', 'surau'],
        category: 'general',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/masjid.mp4',
        remoteUrl: '$baseUrl/videos/sibi/masjid_v1.mp4',
        relativePath: 'videos/sibi/masjid_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_minum',
        label: 'Minum',
        aliases: const ['meminum'],
        category: 'activity',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Minum.mp4',
        remoteUrl: '$baseUrl/videos/sibi/minum_v1.mp4',
        relativePath: 'videos/sibi/minum_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_sakit',
        label: 'Sakit',
        aliases: const ['nyeri', 'perih', 'demam'],
        category: 'health',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Sakit.mp4',
        remoteUrl: '$baseUrl/videos/sibi/sakit_v1.mp4',
        relativePath: 'videos/sibi/sakit_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'bisindo_apa_lagi',
        label: 'Apa Lagi',
        aliases: const ['apa lagi'],
        category: 'question',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/apa_lagi_v1.mp4',
        relativePath: 'videos/bisindo/apa_lagi_v1.mp4',
        type: 'phrase',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_baik',
        label: 'Baik',
        aliases: const ['baik', 'bagus', 'oke', 'mantap'],
        category: 'general',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/baik_v1.mp4',
        relativePath: 'videos/bisindo/baik_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_berapa',
        label: 'Berapa',
        aliases: const ['berapa'],
        category: 'question',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/berapa_v1.mp4',
        relativePath: 'videos/bisindo/berapa_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_berdiri',
        label: 'Berdiri',
        aliases: const ['berdiri'],
        category: 'movement',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/berdiri_v1.mp4',
        relativePath: 'videos/bisindo/berdiri_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_coklat',
        label: 'Coklat',
        aliases: const ['coklat', 'cokelat', 'chocolate'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/coklat_v1.mp4',
        relativePath: 'videos/bisindo/coklat_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_dingin',
        label: 'Dingin',
        aliases: const ['dingin', 'es', 'ice'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/dingin_v1.mp4',
        relativePath: 'videos/bisindo/dingin_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_duduk',
        label: 'Duduk',
        aliases: const ['duduk'],
        category: 'movement',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/duduk_v1.mp4',
        relativePath: 'videos/bisindo/duduk_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_duduk_dimana',
        label: 'Duduk Dimana',
        aliases: const ['duduk dimana', 'duduk di mana'],
        category: 'question',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/duduk_dimana_v1.mp4',
        relativePath: 'videos/bisindo/duduk_dimana_v1.mp4',
        type: 'phrase',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_enak',
        label: 'Enak',
        aliases: const ['enak', 'lezat'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/enak_v1.mp4',
        relativePath: 'videos/bisindo/enak_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_f',
        label: 'F',
        aliases: const ['f'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/f_v1.mp4',
        relativePath: 'videos/bisindo/f_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_g',
        label: 'G',
        aliases: const ['g'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/g_v1.mp4',
        relativePath: 'videos/bisindo/g_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_h',
        label: 'H',
        aliases: const ['h'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/h_v1.mp4',
        relativePath: 'videos/bisindo/h_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_i',
        label: 'I',
        aliases: const ['i'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/i_v1.mp4',
        relativePath: 'videos/bisindo/i_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_j',
        label: 'J',
        aliases: const ['j'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/j_v1.mp4',
        relativePath: 'videos/bisindo/j_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_k',
        label: 'K',
        aliases: const ['k'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/k_v1.mp4',
        relativePath: 'videos/bisindo/k_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kalian',
        label: 'Kalian',
        aliases: const ['kalian'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/kalian_v1.mp4',
        relativePath: 'videos/bisindo/kalian_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kami',
        label: 'Kami',
        aliases: const ['kami'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/kami_v1.mp4',
        relativePath: 'videos/bisindo/kami_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kamu',
        label: 'Kamu',
        aliases: const ['kamu', 'anda', 'engkau', 'lu'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/kamu_v1.mp4',
        relativePath: 'videos/bisindo/kamu_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kapan',
        label: 'Kapan',
        aliases: const ['kapan'],
        category: 'question',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/kapan_v1.mp4',
        relativePath: 'videos/bisindo/kapan_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kemana',
        label: 'Kemana',
        aliases: const ['kemana'],
        category: 'question',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/kemana_v1.mp4',
        relativePath: 'videos/bisindo/kemana_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kentang',
        label: 'Kentang',
        aliases: const ['kentang', 'kentang goreng', 'french fries'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/kentang_v1.mp4',
        relativePath: 'videos/bisindo/kentang_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kita',
        label: 'Kita',
        aliases: const ['kita'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/kita_v1.mp4',
        relativePath: 'videos/bisindo/kita_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_l',
        label: 'L',
        aliases: const ['l'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/l_v1.mp4',
        relativePath: 'videos/bisindo/l_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_m',
        label: 'M',
        aliases: const ['m'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/m_v1.mp4',
        relativePath: 'videos/bisindo/m_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_manis',
        label: 'Manis',
        aliases: const ['manis'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/manis_v1.mp4',
        relativePath: 'videos/bisindo/manis_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_matcha',
        label: 'Matcha',
        aliases: const ['matcha', 'green tea'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/matcha_v1.mp4',
        relativePath: 'videos/bisindo/matcha_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_mau',
        label: 'Mau',
        aliases: const ['mau', 'ingin'],
        category: 'general',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/mau_v1.mp4',
        relativePath: 'videos/bisindo/mau_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_mi_goreng',
        label: 'Mi Goreng',
        aliases: const ['mi goreng', 'mie goreng'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/mi_goreng_v1.mp4',
        relativePath: 'videos/bisindo/mi_goreng_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_mi_rebus',
        label: 'Mi Rebus',
        aliases: const ['mi rebus', 'mie rebus', 'mi kuah'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/mi_rebus_v1.mp4',
        relativePath: 'videos/bisindo/mi_rebus_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_n',
        label: 'N',
        aliases: const ['n'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/n_v1.mp4',
        relativePath: 'videos/bisindo/n_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_nasi_goreng',
        label: 'Nasi Goreng',
        aliases: const ['nasi goreng'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/nasi_goreng_v1.mp4',
        relativePath: 'videos/bisindo/nasi_goreng_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_o',
        label: 'O',
        aliases: const ['o'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/o_v1.mp4',
        relativePath: 'videos/bisindo/o_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_p',
        label: 'P',
        aliases: const ['p'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/p_v1.mp4',
        relativePath: 'videos/bisindo/p_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_panas',
        label: 'Panas',
        aliases: const ['panas', 'hangat', 'hot'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/panas_v1.mp4',
        relativePath: 'videos/bisindo/panas_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_pedas',
        label: 'Pedas',
        aliases: const ['pedas'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/pedas_v1.mp4',
        relativePath: 'videos/bisindo/pedas_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_pedas_tidak_pedas',
        label: 'Pedas / Tidak Pedas',
        aliases: const ['pedas tidak pedas', 'tingkat pedas'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/pedas_tidak_pedas_v1.mp4',
        relativePath: 'videos/bisindo/pedas_tidak_pedas_v1.mp4',
        type: 'phrase',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_pesan',
        label: 'Pesan',
        aliases: const ['pesan', 'order'],
        category: 'activity',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/pesan_v1.mp4',
        relativePath: 'videos/bisindo/pesan_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_pisang_goreng',
        label: 'Pisang Goreng',
        aliases: const ['pisang goreng', 'pisgor'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/pisang_goreng_v1.mp4',
        relativePath: 'videos/bisindo/pisang_goreng_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_q',
        label: 'Q',
        aliases: const ['q'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/q_v1.mp4',
        relativePath: 'videos/bisindo/q_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_r',
        label: 'R',
        aliases: const ['r'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/r_v1.mp4',
        relativePath: 'videos/bisindo/r_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_s',
        label: 'S',
        aliases: const ['s'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/s_v1.mp4',
        relativePath: 'videos/bisindo/s_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_sama_sama',
        label: 'Sama-sama',
        aliases: const ['sama-sama', 'sama sama', 'kembali'],
        category: 'courtesy',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/sama_sama_v1.mp4',
        relativePath: 'videos/bisindo/sama_sama_v1.mp4',
        type: 'phrase',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_saya',
        label: 'Saya',
        aliases: const ['saya', 'aku', 'gue'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/saya_v1.mp4',
        relativePath: 'videos/bisindo/saya_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_selamat_menikmati',
        label: 'Selamat Menikmati',
        aliases: const ['selamat menikmati'],
        category: 'courtesy',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/selamat_menikmati_v1.mp4',
        relativePath: 'videos/bisindo/selamat_menikmati_v1.mp4',
        type: 'sentence',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_siapa',
        label: 'Siapa',
        aliases: const ['siapa'],
        category: 'question',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/siapa_v1.mp4',
        relativePath: 'videos/bisindo/siapa_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_t',
        label: 'T',
        aliases: const ['t'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/t_v1.mp4',
        relativePath: 'videos/bisindo/t_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_teh',
        label: 'Teh',
        aliases: const ['teh', 'tea'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/teh_v1.mp4',
        relativePath: 'videos/bisindo/teh_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_thai_tea',
        label: 'Thai Tea',
        aliases: const ['thai tea', 'teh thailand'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/thai_tea_v1.mp4',
        relativePath: 'videos/bisindo/thai_tea_v1.mp4',
        type: 'word',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_tidak_manis_less_sugar',
        label: 'Tidak Manis / Less Sugar',
        aliases: const ['tidak manis', 'less sugar', 'kurang manis', 'tanpa gula'],
        category: 'food_beverage',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/tidak_manis_less_sugar_v1.mp4',
        relativePath: 'videos/bisindo/tidak_manis_less_sugar_v1.mp4',
        type: 'phrase',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_u',
        label: 'U',
        aliases: const ['u'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/u_v1.mp4',
        relativePath: 'videos/bisindo/u_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_v',
        label: 'V',
        aliases: const ['v'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/v_v1.mp4',
        relativePath: 'videos/bisindo/v_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_w',
        label: 'W',
        aliases: const ['w'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/w_v1.mp4',
        relativePath: 'videos/bisindo/w_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_x',
        label: 'X',
        aliases: const ['x'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/x_v1.mp4',
        relativePath: 'videos/bisindo/x_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_y',
        label: 'Y',
        aliases: const ['y'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/y_v1.mp4',
        relativePath: 'videos/bisindo/y_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_z',
        label: 'Z',
        aliases: const ['z'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/bisindo/z_v1.mp4',
        relativePath: 'videos/bisindo/z_v1.mp4',
        type: 'letter',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'sibi_beli',
        label: 'Beli',
        aliases: const ['beli'],
        category: 'general',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/sibi/beli_v1.mp4',
        relativePath: 'videos/sibi/beli_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_dokter',
        label: 'Dokter',
        aliases: const ['dokter'],
        category: 'health',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/sibi/dokter_v1.mp4',
        relativePath: 'videos/sibi/dokter_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_hilang',
        label: 'Hilang',
        aliases: const ['hilang'],
        category: 'general',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/sibi/hilang_v1.mp4',
        relativePath: 'videos/sibi/hilang_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_mana',
        label: 'Mana',
        aliases: const ['mana'],
        category: 'question',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/sibi/mana_v1.mp4',
        relativePath: 'videos/sibi/mana_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_obat',
        label: 'Obat',
        aliases: const ['obat', 'resep', 'farmasi', 'pil'],
        category: 'health',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/sibi/obat_v1.mp4',
        relativePath: 'videos/sibi/obat_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_segera',
        label: 'Segera',
        aliases: const ['segera'],
        category: 'general',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/sibi/segera_v1.mp4',
        relativePath: 'videos/sibi/segera_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_sesat',
        label: 'Sesat',
        aliases: const ['sesat'],
        category: 'general',
        assetPath: '',
        remoteUrl: '$baseUrl/videos/sibi/sesat_v1.mp4',
        relativePath: 'videos/sibi/sesat_v1.mp4',
        type: 'word',
        signSystem: 'sibi',
      ),
    ];

    return SignLanguageCatalog(entries: rawList);
  }
}
