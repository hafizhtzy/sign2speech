import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../sign_language/services/bisindo_tts_service.dart';

class SettingsController extends GetxController with WidgetsBindingObserver {
  static const String _keyRole = 'user_selected_role';
  static const String _keySignLang = 'user_selected_sign_language';
  static const String _keyAppLang = 'pref_app_lang';
  static const String _keyAppLangLegacy = 'user_selected_app_language';
  static const String _keyTtsSpeed = 'user_tts_speed';
  static const String _keyVideoSpeed = 'user_video_speed';
  static const String _keyOnboarded = 'has_completed_onboarding';
  static const String _keyThemeMode = 'user_selected_theme_mode';

  final RxString selectedRole = 'Teman Tuli'.obs;
  final RxString selectedSignLanguage = 'BISINDO'.obs;
  final RxString selectedAppLanguage = 'id'.obs;
  final RxDouble ttsSpeed = 1.0.obs;
  final RxDouble videoSpeed = 1.0.obs;
  final RxBool hasCompletedOnboarding = false.obs;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  bool get isDarkMode {
    if (themeMode.value == ThemeMode.dark) return true;
    if (themeMode.value == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadPreferences();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangePlatformBrightness() {
    if (themeMode.value == ThemeMode.system) {
      final isDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
      AppColors.isDarkModeOverride = isDark;
      Get.changeTheme(isDark ? AppTheme.darkTheme : AppTheme.lightTheme);
      _syncSystemOverlayStyle(ThemeMode.system);
      themeMode.refresh();
      update();
    }
  }

  Locale getLocaleForLanguage(String langCode) {
    if (langCode == 'en') {
      return const Locale('en', 'US');
    }
    return const Locale('id', 'ID');
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    selectedRole.value = prefs.getString(_keyRole) ?? 'Teman Tuli';
    selectedSignLanguage.value = prefs.getString(_keySignLang) ?? 'BISINDO';

    // Theme Mode preference (Instagram AMOLED Dark Mode, Light Mode, or System)
    final savedTheme = prefs.getString(_keyThemeMode);
    if (savedTheme == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
    }

    AppColors.isDarkModeOverride = isDarkMode;
    Get.changeThemeMode(themeMode.value);
    Get.changeTheme(isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme);
    _syncSystemOverlayStyle(themeMode.value);

    // App Language preference: default to 'id' unless user previously saved
    final savedLang = prefs.getString(_keyAppLang) ?? prefs.getString(_keyAppLangLegacy);
    if (savedLang != null) {
      selectedAppLanguage.value = savedLang;
      final targetLocale = getLocaleForLanguage(savedLang);
      if (Get.context != null && Get.locale?.languageCode != targetLocale.languageCode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.context != null) {
            Get.updateLocale(targetLocale);
          }
        });
      }
    } else {
      selectedAppLanguage.value = 'id';
    }

    ttsSpeed.value = prefs.getDouble(_keyTtsSpeed) ?? 1.0;
    videoSpeed.value = prefs.getDouble(_keyVideoSpeed) ?? 1.0;
    hasCompletedOnboarding.value = prefs.getBool(_keyOnboarded) ?? false;

    // Sync TTS language and speed immediately
    if (Get.isRegistered<BisindoTtsService>()) {
      final tts = Get.find<BisindoTtsService>();
      tts.setLanguage(selectedAppLanguage.value);
      tts.setSpeechRate(ttsSpeed.value);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final bool newIsDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    // 1. Synchronously set AppColors override BEFORE triggering any Obx
    AppColors.isDarkModeOverride = newIsDark;

    // 2. Synchronously notify GetX framework & system UI overlays
    Get.changeThemeMode(mode);
    Get.changeTheme(newIsDark ? AppTheme.darkTheme : AppTheme.lightTheme);
    _syncSystemOverlayStyle(mode);

    // 3. Update reactive variable to synchronously trigger Obx rebuilds everywhere
    themeMode.value = mode;
    update();

    // 4. Persist to storage asynchronously in the background
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeStr = 'system';
      if (mode == ThemeMode.light) modeStr = 'light';
      if (mode == ThemeMode.dark) modeStr = 'dark';
      await prefs.setString(_keyThemeMode, modeStr);
    } catch (_) {}
  }

  Future<void> testTtsVoice() async {
    HapticFeedback.lightImpact();
    if (Get.isRegistered<BisindoTtsService>()) {
      final tts = Get.find<BisindoTtsService>();
      final isEn = selectedAppLanguage.value == 'en';
      final sample = isEn
          ? 'Hello! This is a test of the Sign2Speech voice rate.'
          : 'Halo! Ini adalah uji coba kecepatan suara Sign2Speech.';
      await tts.setSpeechRate(ttsSpeed.value);
      await tts.speak(sample, languageCode: selectedAppLanguage.value);
    }
  }

  void _syncSystemOverlayStyle(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  Future<void> setAppLanguage(String langCode) async {
    // 1. Immediately update reactive state
    selectedAppLanguage.value = langCode;
    final targetLocale = getLocaleForLanguage(langCode);
    if (Get.context != null) {
      final isTesting = WidgetsBinding.instance.runtimeType
          .toString()
          .contains('TestWidgetsFlutterBinding');
      if (isTesting) {
        Get.locale = targetLocale;
      } else {
        await Get.updateLocale(targetLocale);
      }
    }
    if (Get.isRegistered<BisindoTtsService>()) {
      await Get.find<BisindoTtsService>().setLanguage(langCode);
    }
    update();

    // 2. Persist to storage in background
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAppLang, langCode);
      await prefs.setString(_keyAppLangLegacy, langCode);
    } catch (_) {}
  }

  Future<void> setRole(String role) async {
    selectedRole.value = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  Future<void> setSignLanguage(String lang) async {
    selectedSignLanguage.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySignLang, lang);
  }

  Future<void> setTtsSpeed(double speed) async {
    ttsSpeed.value = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsSpeed, speed);
    if (Get.isRegistered<BisindoTtsService>()) {
      await Get.find<BisindoTtsService>().setSpeechRate(speed);
    }
  }

  Future<void> setVideoSpeed(double speed) async {
    videoSpeed.value = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVideoSpeed, speed);
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
  }
}
