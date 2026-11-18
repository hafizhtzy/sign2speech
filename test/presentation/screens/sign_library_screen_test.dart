import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
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
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const SignLibraryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: Shows All entries, clean language pills without explicit vocab counts
      final semuaTab = find.text('Semua').first;
      final bisindoTab = find.text('BISINDO').first;
      final sibiTab = find.text('SIBI').first;
      expect(semuaTab, findsOneWidget);
      expect(bisindoTab, findsOneWidget);
      expect(sibiTab, findsOneWidget);
      expect(find.textContaining('Semua ('), findsNothing);
      expect(find.textContaining('BISINDO ('), findsNothing);
      expect(find.textContaining('SIBI ('), findsNothing);
      expect(find.textContaining('isyarat)'), findsNothing);

      // Initial view should contain top visible items
      expect(find.text('Halo'), findsOneWidget);

      // 2. Tap SIBI filter pill
      await tester.tap(sibiTab);
      await tester.pumpAndSettle();

      // Should show SIBI items (Aku, Bantu), but hide BISINDO-only items like 'Halo'
      expect(find.text('Aku'), findsOneWidget);
      expect(find.text('Bantu'), findsOneWidget);
      expect(find.text('Halo'), findsNothing);

      // 3. Tap BISINDO filter pill
      await tester.tap(bisindoTab);
      await tester.pumpAndSettle();

      // Should show BISINDO items (Halo), but hide SIBI items like 'Aku'
      expect(find.text('Halo'), findsOneWidget);
      expect(find.text('Aku'), findsNothing);

      // 4. Test Category Filter Pill: Tap ChoiceChip 'Harian'
      // Return to 'Semua' language
      await tester.tap(semuaTab);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Harian'));
      await tester.pumpAndSettle();

      // 'Air' is in Harian category, but 'Halo' (Salam) is not
      expect(find.text('Air'), findsOneWidget);
      expect(find.text('Halo'), findsNothing);
    },
  );

  testWidgets(
    'SignLibraryScreen paginates entries and updates page controls correctly',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: const SignLibraryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal PaginationControlBar
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Check pagination info on page 1 (no explicit vocab count shown)
      expect(find.text('Halaman 1 dari 8'), findsOneWidget);
      expect(find.textContaining('kosakata'), findsNothing);

      // Tap Page 2 chip
      final page2Finder = find.widgetWithText(InkWell, '2');
      expect(page2Finder, findsWidgets);
      await tester.tap(page2Finder.first);
      await tester.pumpAndSettle();

      // Scroll to verify updated pagination state
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Halaman 2 dari 8'), findsOneWidget);
      expect(find.textContaining('kosakata'), findsNothing);
    },
  );
}
