import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/features/sign_language/controllers/text_to_sign_controller.dart';
import 'package:speech2sign/features/sign_language/models/sign_language_catalog.dart';
import 'package:speech2sign/features/sign_language/services/sign_language_repository.dart';
import 'package:speech2sign/presentation/screens/sign_library_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    final catalog = SignLanguageCatalog.defaultCatalog();
    final repository = SignLanguageRepository(catalog: catalog);
    Get.put<SignLanguageRepository>(repository);
    Get.put<TextToSignController>(TextToSignController(repository: repository));
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'SignLibraryScreen renders language segmented pills and filters BISINDO vs SIBI correctly',
    (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: SignLibraryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: Shows All entries, language pills 'Semua', 'BISINDO', 'SIBI'
      expect(find.textContaining('Semua ('), findsOneWidget);
      expect(find.textContaining('BISINDO ('), findsOneWidget);
      expect(find.textContaining('SIBI ('), findsOneWidget);

      // Initial view should contain top visible items
      expect(find.text('Halo'), findsOneWidget);

      // 2. Tap SIBI filter pill
      await tester.tap(find.textContaining('SIBI ('));
      await tester.pumpAndSettle();

      // Should show SIBI items (Aku, Bantu), but hide BISINDO-only items like 'Halo'
      expect(find.text('Aku'), findsOneWidget);
      expect(find.text('Bantu'), findsOneWidget);
      expect(find.text('Halo'), findsNothing);

      // 3. Tap BISINDO filter pill
      await tester.tap(find.textContaining('BISINDO ('));
      await tester.pumpAndSettle();

      // Should show BISINDO items (Halo), but hide SIBI items like 'Aku'
      expect(find.text('Halo'), findsOneWidget);
      expect(find.text('Aku'), findsNothing);

      // 4. Test Category Filter Pill: Tap ChoiceChip 'Harian'
      // Return to 'Semua' language
      await tester.tap(find.textContaining('Semua ('));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Harian'));
      await tester.pumpAndSettle();

      // 'Air' is in Harian category, but 'Halo' (Salam) is not
      expect(find.text('Air'), findsOneWidget);
      expect(find.text('Halo'), findsNothing);
    },
  );
}
