import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/core/theme/app_theme.dart';
import 'package:speech2sign/presentation/navigation/app_binding.dart';
import 'package:speech2sign/presentation/navigation/app_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_completed_onboarding': true,
      'user_selected_role': 'Teman Tuli',
      'user_selected_sign_language': 'BISINDO',
    });
    Get.reset();
  });

  group('Screens Integration & Navigation Tests', () {
    testWidgets('App initializes with AppBinding and navigates across tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          initialBinding: AppBinding(),
          initialRoute: AppRoutes.mainShell,
          getPages: AppPages.pages,
        ),
      );

      await tester.pumpAndSettle();

      // Home Screen Verification
      expect(find.text('Sign2Speech'), findsOneWidget);
      expect(find.text('Sign to Speech'), findsOneWidget);
      expect(find.text('Speech to Sign'), findsOneWidget);

      // Verify all 4 bottom nav items
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Perpustakaan'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);

      // Switch to Riwayat tab
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Riwayat Percakapan'), findsOneWidget);

      // Switch to Perpustakaan tab
      await tester.tap(find.text('Perpustakaan'));
      await tester.pumpAndSettle();
      expect(find.text('Perpustakaan Isyarat'), findsOneWidget);

      // Switch to Pengaturan tab
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Pengaturan'), findsOneWidget);
      expect(find.text('Preferensi Bahasa & Peran'), findsOneWidget);
    });
  });
}
