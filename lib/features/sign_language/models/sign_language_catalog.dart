import 'package:flutter/foundation.dart';

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
    for (final entry in entries) {
      if (entry.label.toLowerCase() == clean) {
        if (preferredSystem == null ||
            entry.signSystem.toLowerCase() == preferredSystem.toLowerCase()) {
          return entry;
        }
      }
    }
    return null;
  }

  /// Mencari kecocokan tepat dengan fallback lintas bahasa.
  /// Digunakan saat ingin menemukan video meskipun tidak ada di bahasa pilihan.
  SignVideoEntry? findExactWithFallback(
    String query, [
    String? preferredSystem,
  ]) {
    // Coba bahasa pilihan dulu
    final preferred = findExact(query, preferredSystem);
    if (preferred != null) return preferred;
    // Fallback ke bahasa lain jika preferredSystem diberikan
    if (preferredSystem != null) return findExact(query, null);
    return null;
  }

  /// Mencari kecocokan berdasarkan alias/sinonim.
  /// Jika [preferredSystem] ditentukan, HANYA mencari di bahasa tersebut (tanpa fallback lintas bahasa).
  SignVideoEntry? findByAlias(String query, [String? preferredSystem]) {
    final clean = query.trim().toLowerCase();
    for (final entry in entries) {
      for (final alias in entry.aliases) {
        if (alias.toLowerCase() == clean) {
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

  /// Parser resmi untuk file JSON katalog haji-sign
  factory SignLanguageCatalog.fromJson(
    Map<String, dynamic> json, {
    String baseUrl = 'https://hajicare-sign.web.app',
  }) {
    final rawVideos = json['videos'] as List? ?? [];
    final List<SignVideoEntry> parsedEntries = [];

    for (final raw in rawVideos) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id'] as String? ?? '';
      final language = (raw['language'] as String? ?? 'bisindo').toLowerCase();
      final label = raw['label'] as String? ?? '';
      final aliases = List<String>.from(raw['aliases'] as List? ?? []);
      final category = raw['category'] as String? ?? 'general';
      final path = raw['path'] as String? ?? '';

      final remoteUrl = path.startsWith('http')
          ? path
          : '$baseUrl/${path.replaceAll(RegExp(r'^/+'), '')}';

      parsedEntries.add(
        SignVideoEntry(
          id: id,
          label: label,
          aliases: aliases,
          category: category,
          assetPath: '',
          remoteUrl: remoteUrl,
          signSystem: language,
        ),
      );
    }

    return SignLanguageCatalog(entries: parsedEntries);
  }

  factory SignLanguageCatalog.defaultCatalog() {
    const rawList = <SignVideoEntry>[
      // ==========================================
      // 1. OFFLINE BUNDLED VIDEOS: BISINDO KALIMAT (APK Assets)
      // ==========================================
      SignVideoEntry(
        id: 'halo',
        label: 'Halo',
        aliases: ['hai', 'hei', 'hallo'],
        category: 'salam',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Halo.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/halo_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'terima_kasih',
        label: 'Terima Kasih',
        aliases: ['makasih', 'nuhun', 'thank you', 'trims', 'matur nuwun'],
        category: 'salam',
        assetPath:
            'assets/sign_language/offline/bisindo/kalimat/Terima_Kasih.mp4',
        remoteUrl:
            'https://hajicare-sign.web.app/videos/bisindo/terima_kasih_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'air',
        label: 'Air',
        aliases: ['air putih', 'aqua', 'minum air'],
        category: 'harian',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Air.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/air_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'apa',
        label: 'Apa',
        aliases: ['apakah', 'ada apa', 'apaan'],
        category: 'harian',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Apa.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/apa_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'apa_kabar',
        label: 'Apa Kabar',
        aliases: ['gimana kabar', 'bagaimana kabar', 'kabarmu'],
        category: 'salam',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Apa_Kabar.mp4',
        remoteUrl:
            'https://hajicare-sign.web.app/videos/bisindo/apa_kabar_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'dimana',
        label: 'Dimana',
        aliases: ['di mana', 'dimanakah', 'ke mana'],
        category: 'harian',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Dimana.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/dimana_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'minum',
        label: 'Minum',
        aliases: ['meminum', 'minuman'],
        category: 'harian',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Minum.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/minum_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'kopi',
        label: 'Kopi',
        aliases: ['kopi', 'minum kopi', 'secangkir kopi', 'coffee'],
        category: 'harian',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Kopi.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/kopi_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'tuli',
        label: 'Tuli',
        aliases: ['teman tuli', 'tunarungu', 'disabilitas rungu'],
        category: 'harian',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Tuli.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/tuli_v1.mp4',
        signSystem: 'bisindo',
      ),

      // ==========================================
      // 2. OFFLINE BUNDLED VIDEOS: BISINDO ALFABET A - E (APK Assets)
      // ==========================================
      SignVideoEntry(
        id: 'bisindo_a',
        label: 'A',
        aliases: ['a', 'huruf a'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/A.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/a_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_b',
        label: 'B',
        aliases: ['b', 'huruf b'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/B.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/b_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_c',
        label: 'C',
        aliases: ['c', 'huruf c'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/C.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/c_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_d',
        label: 'D',
        aliases: ['d', 'huruf d'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/D.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/d_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_e',
        label: 'E',
        aliases: ['e', 'huruf e'],
        category: 'alphabet',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/E.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/e_v1.mp4',
        signSystem: 'bisindo',
      ),

      // ==========================================
      // 3. OFFLINE BUNDLED VIDEOS: SIBI KALIMAT (APK Assets)
      // ==========================================
      SignVideoEntry(
        id: 'sibi_aku',
        label: 'Aku',
        aliases: ['saya', 'gue', 'kulo'],
        category: 'general',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Aku.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/aku_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_bantu',
        label: 'Bantu',
        aliases: ['tolong', 'bantuan', 'mohon bantuan', 'tolong bantu'],
        category: 'general',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/bantu.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/bantu_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_haus',
        label: 'Haus',
        aliases: ['dahaga', 'kering tenggorokan'],
        category: 'health',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Haus.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/haus_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_kami',
        label: 'Kami',
        aliases: ['kita semua'],
        category: 'pronoun',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Kami.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/kami_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_kamu',
        label: 'Kamu',
        aliases: ['anda', 'engkau', 'saudara', 'bapak', 'ibu'],
        category: 'pronoun',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Kamu.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/kamu_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_lapar',
        label: 'Lapar',
        aliases: ['kelaparan', 'mau makan'],
        category: 'general',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Lapar.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/lapar_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_lelah',
        label: 'Lelah',
        aliases: ['capek', 'letih', 'penat'],
        category: 'health',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Lelah.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/lelah_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_makan',
        label: 'Makan',
        aliases: ['santap', 'makanan', 'makan nasi'],
        category: 'general',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Makan.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/makan_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_masjid',
        label: 'Masjid',
        aliases: ['musholla', 'surau', 'tempat shalat'],
        category: 'general',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/masjid.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/masjid_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_minum',
        label: 'Minum',
        aliases: ['meminum', 'minuman'],
        category: 'general',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Minum.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/minum_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_sakit',
        label: 'Sakit',
        aliases: ['nyeri', 'keluhan', 'pedih'],
        category: 'health',
        assetPath: 'assets/sign_language/offline/sibi/kalimat/Sakit.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/sakit_v1.mp4',
        signSystem: 'sibi',
      ),

      // ==========================================
      // 4. RESMI CDN HAJI-SIGN CATALOG: BISINDO KATA (13 Video)
      // ==========================================
      SignVideoEntry(
        id: 'bisindo_baik',
        label: 'Baik',
        aliases: ['baik', 'bagus', 'siap', 'alhamdulillah', 'kabar baik'],
        category: 'general',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/baik_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_berapa',
        label: 'Berapa',
        aliases: ['berapa', 'seberapa', 'jumlahnya'],
        category: 'question',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/berapa_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_berdiri',
        label: 'Berdiri',
        aliases: ['berdiri', 'tegak'],
        category: 'movement',
        assetPath: '',
        remoteUrl:
            'https://hajicare-sign.web.app/videos/bisindo/berdiri_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_dia',
        label: 'Dia',
        aliases: ['dia', 'ia', 'beliau'],
        category: 'pronoun',
        assetPath: 'assets/sign_language/offline/bisindo/alfabet/Dia.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/dia_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_duduk',
        label: 'Duduk',
        aliases: ['duduk', 'silakan duduk'],
        category: 'movement',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/duduk_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kalian',
        label: 'Kalian',
        aliases: ['kalian', 'kamu sekalian'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/kalian_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kami',
        label: 'Kami',
        aliases: ['kami', 'kita'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/kami_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kamu',
        label: 'Kamu',
        aliases: ['kamu', 'anda', 'engkau'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/kamu_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kapan',
        label: 'Kapan',
        aliases: ['kapan', 'waktunya kapan'],
        category: 'question',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/kapan_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kemana',
        label: 'Kemana',
        aliases: ['kemana', 'ke mana', 'tujuan mana'],
        category: 'question',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/kemana_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_kita',
        label: 'Kita',
        aliases: ['kita', 'kita semua'],
        category: 'pronoun',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/kita_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_mandi',
        label: 'Mandi',
        aliases: ['mandi', 'cuci badan'],
        category: 'activity',
        assetPath: 'assets/sign_language/offline/bisindo/kalimat/Mandi.mp4',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/mandi_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_siapa',
        label: 'Siapa',
        aliases: ['siapa', 'siapakah'],
        category: 'question',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/siapa_v1.mp4',
        signSystem: 'bisindo',
      ),

      // ==========================================
      // 5. RESMI CDN HAJI-SIGN CATALOG: BISINDO ALFABET F - Z (21 Video)
      // ==========================================
      SignVideoEntry(
        id: 'bisindo_f',
        label: 'F',
        aliases: ['f', 'huruf f'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/f_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_g',
        label: 'G',
        aliases: ['g', 'huruf g'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/g_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_h',
        label: 'H',
        aliases: ['h', 'huruf h'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/h_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_i',
        label: 'I',
        aliases: ['i', 'huruf i'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/i_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_j',
        label: 'J',
        aliases: ['j', 'huruf j'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/j_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_k',
        label: 'K',
        aliases: ['k', 'huruf k'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/k_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_l',
        label: 'L',
        aliases: ['l', 'huruf l'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/l_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_m',
        label: 'M',
        aliases: ['m', 'huruf m'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/m_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_n',
        label: 'N',
        aliases: ['n', 'huruf n'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/n_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_o',
        label: 'O',
        aliases: ['o', 'huruf o'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/o_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_p',
        label: 'P',
        aliases: ['p', 'huruf p'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/p_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_q',
        label: 'Q',
        aliases: ['q', 'huruf q'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/q_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_r',
        label: 'R',
        aliases: ['r', 'huruf r'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/r_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_s',
        label: 'S',
        aliases: ['s', 'huruf s'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/s_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_t',
        label: 'T',
        aliases: ['t', 'huruf t'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/t_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_u',
        label: 'U',
        aliases: ['u', 'huruf u'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/u_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_v',
        label: 'V',
        aliases: ['v', 'huruf v'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/v_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_w',
        label: 'W',
        aliases: ['w', 'huruf w'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/w_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_x',
        label: 'X',
        aliases: ['x', 'huruf x'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/x_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_y',
        label: 'Y',
        aliases: ['y', 'huruf y'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/y_v1.mp4',
        signSystem: 'bisindo',
      ),
      SignVideoEntry(
        id: 'bisindo_z',
        label: 'Z',
        aliases: ['z', 'huruf z'],
        category: 'alphabet',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/bisindo/z_v1.mp4',
        signSystem: 'bisindo',
      ),

      // ==========================================
      // 6. RESMI CDN HAJI-SIGN CATALOG: SIBI KATA (7 Video)
      // ==========================================
      SignVideoEntry(
        id: 'sibi_beli',
        label: 'Beli',
        aliases: ['beli', 'membeli', 'pembelian', 'order'],
        category: 'general',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/beli_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_dokter',
        label: 'Dokter',
        aliases: ['dokter', 'tenaga medis', 'medis', 'mantri'],
        category: 'health',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/dokter_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_hilang',
        label: 'Hilang',
        aliases: ['hilang', 'kehilangan', 'lenyap'],
        category: 'general',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/hilang_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_mana',
        label: 'Mana',
        aliases: ['mana', 'di mana', 'kemana'],
        category: 'question',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/mana_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_obat',
        label: 'Obat',
        aliases: ['obat', 'resep', 'farmasi', 'pil', 'kapsul'],
        category: 'health',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_segera',
        label: 'Segera',
        aliases: ['segera', 'cepat', 'lekas', 'darurat'],
        category: 'general',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/segera_v1.mp4',
        signSystem: 'sibi',
      ),
      SignVideoEntry(
        id: 'sibi_sesat',
        label: 'Sesat',
        aliases: ['sesat', 'tersesat', 'salah jalan'],
        category: 'general',
        assetPath: '',
        remoteUrl: 'https://hajicare-sign.web.app/videos/sibi/sesat_v1.mp4',
        signSystem: 'sibi',
      ),
    ];

    return const SignLanguageCatalog(entries: rawList);
  }
}
