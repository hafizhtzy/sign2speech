import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/core/theme/app_theme.dart';
import 'package:speech2sign/features/settings/controllers/settings_controller.dart';
import 'package:speech2sign/presentation/navigation/app_binding.dart';
import 'package:speech2sign/presentation/screens/home_screen.dart';

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

  group('HomeScreen Header Responsiveness Tests', () {
    testWidgets('Header renders cleanly in Teman Tuli mode on 360x640 screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      AppBinding().dependencies();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign2Speech'), findsOneWidget);
      expect(find.text('Teman Tuli'), findsOneWidget);
      expect(find.text('BISINDO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Header renders cleanly in Teman Dengar mode on 360x640 screen without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      AppBinding().dependencies();
      final settings = Get.find<SettingsController>();
      settings.setRole('Teman Dengar');

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign2Speech'), findsOneWidget);
      expect(find.text('Teman Dengar'), findsOneWidget);
      expect(find.text('BISINDO'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify Text widget properties: maxLines is 1
      final textWidget = tester.widget<Text>(find.text('Sign2Speech'));
      expect(textWidget.maxLines, 1);
    });
  });
}

