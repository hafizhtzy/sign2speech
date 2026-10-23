import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/theme/app_theme.dart';
import 'package:speech2sign/features/settings/controllers/settings_controller.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_cache_service.dart';
import 'package:speech2sign/presentation/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      'user_selected_role': 'Teman Tuli',
      'user_selected_sign_language': 'BISINDO',
      'user_selected_theme_mode': 'light',
    });
    Get.reset();
  });

  tearDown(() {
    AppColors.isDarkModeOverride = null;
    Get.reset();
  });

  group('SettingsScreen UI & Option Sheet Tests', () {
    testWidgets('SettingsScreen renders all sections, options, and reacts to theme changes', (
      tester,
    ) async {
      final settings = Get.put(SettingsController());
      Get.put(BisindoTtsService());
      Get.put(SignLanguageCacheService());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.widgetWithText(AppBar, 'Pengaturan'), findsOneWidget);

      // Verify Preference Section Titles
      expect(find.text('Preferensi Bahasa & Peran'), findsOneWidget);
      expect(find.text('Bahasa Aplikasi'), findsOneWidget);
      expect(find.text('Bahasa Isyarat Aktif'), findsOneWidget);
      expect(find.text('Peran Komunikasi'), findsOneWidget);
      expect(find.text('Tema Tampilan'), findsOneWidget);

      // Verify TTS, Video, and Storage Cards
      expect(find.text('Suara & Audio TTS (id-ID)'), findsOneWidget);
      expect(find.text('Uji Coba Suara'), findsOneWidget);
      expect(find.text('Video Peragaan Isyarat'), findsOneWidget);
      expect(find.text('Penyimpanan & Cache'), findsOneWidget);
      expect(find.text('Bersihkan Cache Video Lokal'), findsOneWidget);

      // Verify initial theme state is light
      expect(settings.themeMode.value, ThemeMode.light);
      expect(AppColors.isDark, isFalse);

      // Tap on Tema Tampilan to open the bottom sheet modal
      await tester.tap(find.text('Tema Tampilan'));
      await tester.pumpAndSettle();

      // Verify Bottom Sheet opened with theme choices
      expect(find.text('Instagram AMOLED Dark Mode'), findsOneWidget);
      expect(find.text('Cafe Warm Oat Milk / Espresso'), findsOneWidget);

      // Select Dark Mode from the sheet
      await tester.tap(find.text('Gelap (Instagram)'));
      await tester.pumpAndSettle();

      // Verify Dark mode was applied
      expect(settings.themeMode.value, ThemeMode.dark);
      expect(AppColors.isDark, isTrue);

      // Tap on Bahasa Aplikasi to open language sheet
      await tester.tap(find.text('Bahasa Aplikasi'));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Bahasa Indonesia'), findsNWidgets(2));

      // Select English
      await tester.tap(find.text('English'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(settings.selectedAppLanguage.value, 'en');

      // Test TTS voice test button (now translated to Test Voice)
      expect(find.text('Test Voice'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded));
      await tester.pump();
    });

    testWidgets(
      'setThemeMode updates AppColors synchronously and instantly without waiting on I/O',
      (tester) async {
        final settings = Get.put(SettingsController());
        Get.put(BisindoTtsService());
        Get.put(SignLanguageCacheService());

        expect(AppColors.isDark, isFalse);
        expect(AppColors.canvas, AppColors.lightCanvas);

        // Trigger theme switch to dark mode
        final future = settings.setThemeMode(ThemeMode.dark);

        // Must be immediately updated synchronously on the same frame, before future completes
        expect(settings.themeMode.value, ThemeMode.dark);
        expect(AppColors.isDark, isTrue);
        expect(AppColors.canvas, AppColors.darkCanvas);
        expect(AppColors.surface, AppColors.darkSurface);

        await future;
        expect(AppColors.isDark, isTrue);

        // Trigger theme switch back to light mode
        final futureLight = settings.setThemeMode(ThemeMode.light);
        expect(settings.themeMode.value, ThemeMode.light);
        expect(AppColors.isDark, isFalse);
        expect(AppColors.canvas, AppColors.lightCanvas);

        await futureLight;
      },
    );
  });
}
