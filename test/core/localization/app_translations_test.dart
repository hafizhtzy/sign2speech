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

      // Cafe POS & Delete Confirmation Localization Verification
      expect(idMap[AppStrings.cafeDeleteOrderTitle], 'Hapus Pesanan?');
      expect(enMap[AppStrings.cafeDeleteOrderTitle], 'Remove Item?');

      expect(idMap[AppStrings.cafeDeleteItem], 'Hapus');
      expect(enMap[AppStrings.cafeDeleteItem], 'Remove');

      expect(idMap[AppStrings.cafeLiveOrderCameraTitle], 'Live Kamera & Suara Pesanan');
      expect(enMap[AppStrings.cafeLiveOrderCameraTitle], 'Live Camera & Voice Order');

      expect(idMap[AppStrings.cafeOrderReady], 'Pesanan Siap Diambil!');
      expect(enMap[AppStrings.cafeOrderReady], 'Order is Ready for Pickup!');

      expect(idMap[AppStrings.cafeOfficialReceipt], 'STRUK RESMI KAFE');
      expect(enMap[AppStrings.cafeOfficialReceipt], 'OFFICIAL CAFE RECEIPT');

      expect(idMap[AppStrings.cafeTodaySignTitle], 'ISYARAT HARI INI:');
      expect(enMap[AppStrings.cafeTodaySignTitle], "TODAY'S SIGN:");

      expect(idMap[AppStrings.cashierGreetingPrompt], 'Halo! Mau pesan apa hari ini?');
      expect(enMap[AppStrings.cashierGreetingPrompt], 'Hello! What would you like to order today?');
    });

    test('Dynamic GetX .tr and .trParams evaluation resolves correctly in both locales', () {
      Get.reset();
      AppTranslations.ensureLoaded();

      Get.locale = const Locale('id', 'ID');
      expect(AppStrings.cafeDeleteOrderTitle.tr, 'Hapus Pesanan?');
      expect(AppStrings.cafeDeleteItem.tr, 'Hapus');
      expect(
        AppStrings.cafeDeleteOrderConfirm.trParams({'name': 'Oat Cappuccino'}),
        'Apakah Anda yakin ingin menghapus Oat Cappuccino dari tiket pesanan?',
      );
      expect(
        AppStrings.cafeSignGuideTitle.trParams({'word': 'KOPI'}),
        'Panduan Isyarat: "KOPI"',
      );
      expect(
        AppStrings.cafeMatchPercentage.trParams({'percent': '95'}),
        '95% Cocok',
      );
      expect(
        AppStrings.cafeTrophyDesc.trParams({'sign': 'KOPI'}),
        'Luar biasa! Gestur "KOPI" berhasil Anda peragakan dengan sempurna. Barista sangat mengapresiasi upaya Anda!',
      );

      Get.locale = const Locale('en', 'US');
      expect(AppStrings.cafeDeleteOrderTitle.tr, 'Remove Item?');
      expect(AppStrings.cafeDeleteItem.tr, 'Remove');
      expect(
        AppStrings.cafeDeleteOrderConfirm.trParams({'name': 'Oat Cappuccino'}),
        'Are you sure you want to remove Oat Cappuccino from the order ticket?',
      );
      expect(
        AppStrings.cafeSignGuideTitle.trParams({'word': 'COFFEE'}),
        'Sign Guide: "COFFEE"',
      );
      expect(
        AppStrings.cafeMatchPercentage.trParams({'percent': '95'}),
        '95% Match',
      );
      expect(
        AppStrings.cafeTrophyDesc.trParams({'sign': 'COFFEE'}),
        'Awesome! You performed the "COFFEE" gesture perfectly. The barista really appreciates your effort!',
      );
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
