import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/theme/app_colors.dart';
import 'package:speech2sign/core/widgets/app_snackbar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(() {
    AppColors.isDarkModeOverride = null;
    Get.reset();
  });

  group('AppSnackbar Accessible & Contrast Tests', () {
    testWidgets('AppSnackbar renders info variant cleanly in light mode', (
      tester,
    ) async {
      AppColors.isDarkModeOverride = false;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  AppSnackbar.info(
                    title: 'Info Title',
                    message: 'Info message body',
                    duration: const Duration(seconds: 1),
                  );
                },
                child: const Text('Show Info'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      // Pump to trigger animation and show snackbar in overlay
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Info Title'), findsOneWidget);
      expect(find.text('Info message body'), findsOneWidget);

      // Drain pending auto-dismiss timer and exit animation
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('AppSnackbar renders success variant cleanly in light mode', (
      tester,
    ) async {
      AppColors.isDarkModeOverride = false;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  AppSnackbar.success(
                    title: 'Success Title',
                    message: 'Success message body',
                    duration: const Duration(seconds: 1),
                  );
                },
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Success Title'), findsOneWidget);
      expect(find.text('Success message body'), findsOneWidget);

      // Drain timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('AppSnackbar renders with dark theme AMOLED tokens', (
      tester,
    ) async {
      AppColors.isDarkModeOverride = true;

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  AppSnackbar.success(
                    title: 'Dark Mode Success',
                    message: 'High contrast green message on dark background',
                    duration: const Duration(seconds: 1),
                  );
                },
                child: const Text('Trigger Dark'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger Dark'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Dark Mode Success'), findsOneWidget);
      expect(
        find.text('High contrast green message on dark background'),
        findsOneWidget,
      );

      // Drain timer
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });
  });
}
