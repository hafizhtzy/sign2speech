import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/theme/app_theme.dart';
import 'package:speech2sign/features/settings/controllers/settings_controller.dart';
import 'package:speech2sign/features/sign_language/controllers/bisindo_recognition_controller.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/presentation/navigation/app_binding.dart';
import 'package:speech2sign/presentation/navigation/app_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'has_completed_onboarding': false});
    Get.reset();
  });

  group('Onboarding & Feature Flow Tests', () {
    testWidgets('Onboarding 1 navigates to Onboarding 2', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialBinding: AppBinding(),
          initialRoute: AppRoutes.onboarding1,
          getPages: AppPages.pages,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Komunikasi Lebih Mudah'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);

      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Untuk Semua Kesempatan'), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsOneWidget);
    });

    testWidgets('Choose Role updates selected role in SettingsController', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialBinding: AppBinding(),
          initialRoute: AppRoutes.chooseRole,
          getPages: AppPages.pages,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pilih Peran'), findsOneWidget);
      expect(find.text('Teman Tuli'), findsOneWidget);
      expect(find.text('Teman Dengar'), findsOneWidget);

      final settings = Get.find<SettingsController>();

      // Tap Teman Dengar
      await tester.tap(find.text('Teman Dengar'));
      await tester.pumpAndSettle();

      // Tap Lanjut
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(settings.selectedRole.value, 'Teman Dengar');
      expect(find.text('Pilih Bahasa Isyarat'), findsOneWidget);
    });

    testWidgets(
      'Sign to Speech Camera updates transcript on gesture simulation',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.lightTheme,
            initialBinding: AppBinding(),
            initialRoute: AppRoutes.signToSpeechCamera,
            getPages: AppPages.pages,
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Teks Terdeteksi'), findsOneWidget);
        expect(find.text('Uji Coba Gestur:'), findsOneWidget);

        // Tap simulation chip 'Halo'
        await tester.tap(find.text('Halo'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 700));

        final recCtrl = Get.find<BisindoRecognitionController>();
        expect(recCtrl.fullTranscriptText.contains('Halo'), isTrue);
        expect(find.textContaining('Halo'), findsWidgets);
      },
    );

    testWidgets('Speech to Sign Mic processes phrase and navigates to result', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialBinding: AppBinding(),
          initialRoute: AppRoutes.speechToSignMic,
          getPages: AppPages.pages,
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Speech to Sign'), findsOneWidget);
      expect(find.text('Bicara Lewat Mikrofon'), findsOneWidget);

      // Tap test chip 'Saya mau beli tiket'
      await tester.tap(find.text('Saya mau beli tiket'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final ttsCtrl = Get.find<TextToSignController>();
      expect(ttsCtrl.recognizedWords.value, 'Saya mau beli tiket');
      expect(find.text('Hasil Speech to Sign'), findsOneWidget);
    });
  });
}
