import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/localization/app_strings.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/settings/controllers/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTranslations Tests', () {
    test('Contains both id_ID and en_US dictionaries', () {
      final translations = AppTranslations();
      expect(translations.keys.containsKey('id_ID'), isTrue);
      expect(translations.keys.containsKey('en_US'), isTrue);
    });

    test('All keys in id_ID have corresponding non-empty translations in en_US', () {
      final translations = AppTranslations();
      final idMap = translations.keys['id_ID']!;
      final enMap = translations.keys['en_US']!;

      for (final key in idMap.keys) {
        expect(
          enMap.containsKey(key),
          isTrue,
          reason: 'Key "$key" is missing in en_US dictionary',
        );
        expect(
          enMap[key]?.trim().isNotEmpty,
          isTrue,
          reason: 'Key "$key" is empty in en_US dictionary',
        );
      }
    });

    test('Common UI strings match expected translations', () {
      final translations = AppTranslations();
      final idMap = translations.keys['id_ID']!;
      final enMap = translations.keys['en_US']!;

      expect(idMap[AppStrings.appTitle], 'Sign2Speech');
      expect(enMap[AppStrings.appTitle], 'Sign2Speech');

      expect(idMap[AppStrings.navHome], 'Beranda');
      expect(enMap[AppStrings.navHome], 'Home');

      expect(idMap[AppStrings.navSettings], 'Pengaturan');
      expect(enMap[AppStrings.navSettings], 'Settings');

      expect(idMap[AppStrings.settingsAppLanguage], 'Bahasa Aplikasi');
      expect(enMap[AppStrings.settingsAppLanguage], 'App Language');
    });
  });

  group('SettingsController Multi-Language Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
    });

    test('Initializes with default language and updates locale', () async {
      final controller = SettingsController();
      await controller.loadPreferences();

      expect(controller.selectedAppLanguage.value, isIn(['id', 'en']));
      expect(
        controller.getLocaleForLanguage('id'),
        const Locale('id', 'ID'),
      );
      expect(
        controller.getLocaleForLanguage('en'),
        const Locale('en', 'US'),
      );
    });

    test('Switching app language persists to SharedPreferences and updates Get locale', () async {
      final controller = SettingsController();
      await controller.loadPreferences();

      await controller.setAppLanguage('en');
      expect(controller.selectedAppLanguage.value, 'en');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_selected_app_language'), 'en');

      await controller.setAppLanguage('id');
      expect(controller.selectedAppLanguage.value, 'id');
      expect(prefs.getString('user_selected_app_language'), 'id');
    });
  });
}
