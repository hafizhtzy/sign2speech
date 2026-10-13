import 'package:flutter/services.dart';

class SignLanguageAssetRegistry {
  final Set<String> _bundledAssets = {};

  SignLanguageAssetRegistry({Set<String>? preloadedAssets}) {
    if (preloadedAssets != null) {
      _bundledAssets.addAll(preloadedAssets);
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
