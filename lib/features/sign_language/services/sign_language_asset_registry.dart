import 'package:flutter/services.dart';

class SignLanguageAssetRegistry {
  /// 27 Preloaded Bundled Offline Video Assets (BISINDO & SIBI)
  static const Set<String> defaultOfflineAssets = {
    // BISINDO Alfabet
    'assets/sign_language/offline/bisindo/alfabet/A.mp4',
    'assets/sign_language/offline/bisindo/alfabet/B.mp4',
    'assets/sign_language/offline/bisindo/alfabet/C.mp4',
    'assets/sign_language/offline/bisindo/alfabet/D.mp4',
    'assets/sign_language/offline/bisindo/alfabet/Dia.mp4',
    'assets/sign_language/offline/bisindo/alfabet/E.mp4',

    // BISINDO Kalimat
    'assets/sign_language/offline/bisindo/kalimat/Air.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Apa.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Apa_Kabar.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Dimana.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Halo.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Kopi.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Mandi.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Minum.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Terima_Kasih.mp4',
    'assets/sign_language/offline/bisindo/kalimat/Tuli.mp4',

    // SIBI Kalimat
    'assets/sign_language/offline/sibi/kalimat/Aku.mp4',
    'assets/sign_language/offline/sibi/kalimat/bantu.mp4',
    'assets/sign_language/offline/sibi/kalimat/Dia.mp4',
    'assets/sign_language/offline/sibi/kalimat/Haus.mp4',
    'assets/sign_language/offline/sibi/kalimat/Kami.mp4',
    'assets/sign_language/offline/sibi/kalimat/Kamu.mp4',
    'assets/sign_language/offline/sibi/kalimat/Lapar.mp4',
    'assets/sign_language/offline/sibi/kalimat/Lelah.mp4',
    'assets/sign_language/offline/sibi/kalimat/Makan.mp4',
    'assets/sign_language/offline/sibi/kalimat/masjid.mp4',
    'assets/sign_language/offline/sibi/kalimat/Minum.mp4',
    'assets/sign_language/offline/sibi/kalimat/Sakit.mp4',
  };

  final Set<String> _bundledAssets = {};

  SignLanguageAssetRegistry({Set<String>? preloadedAssets}) {
    if (preloadedAssets != null) {
      _bundledAssets.addAll(preloadedAssets);
    } else {
      _bundledAssets.addAll(defaultOfflineAssets);
    }
  }

  bool isAssetBundled(String assetPath) {
    return _bundledAssets.contains(assetPath);
  }

  void registerBundledAsset(String assetPath) {
    _bundledAssets.add(assetPath);
  }

  /// Verifies asset existence against Flutter rootBundle
  Future<bool> checkAssetExists(String assetPath) async {
    if (_bundledAssets.contains(assetPath)) return true;
    try {
      await rootBundle.load(assetPath);
      _bundledAssets.add(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
