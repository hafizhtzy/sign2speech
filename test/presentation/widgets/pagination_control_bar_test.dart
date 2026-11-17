import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/presentation/widgets/pagination_control_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'PaginationControlBar renders summary, previous/next, and invokes callbacks',
    (tester) async {
      int selectedPage = 1;

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('id', 'ID'),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PaginationControlBar(
                  currentPage: selectedPage,
                  totalPages: 5,
                  totalItems: 50,
                  itemsPerPage: 10,
                  onPageChanged: (newPage) {
                    setState(() {
                      selectedPage = newPage;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify page summary text
      expect(find.text('Menampilkan 1-10 dari 50 kosakata'), findsOneWidget);
      expect(find.text('Halaman 1 dari 5'), findsOneWidget);

      // Verify page chips 1 to 5 exist
      for (int i = 1; i <= 5; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Tap Next button (Chevron right)
      final nextFinder = find.byIcon(Icons.chevron_right_rounded);
      expect(nextFinder, findsOneWidget);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      expect(selectedPage, 2);
      expect(find.text('Halaman 2 dari 5'), findsOneWidget);
      expect(find.text('Menampilkan 11-20 dari 50 kosakata'), findsOneWidget);

      // Tap Previous button (Chevron left)
      final prevFinder = find.byIcon(Icons.chevron_left_rounded);
      expect(prevFinder, findsOneWidget);
      await tester.tap(prevFinder);
      await tester.pumpAndSettle();

      expect(selectedPage, 1);
      expect(find.text('Halaman 1 dari 5'), findsOneWidget);
    },
  );

  testWidgets('PaginationControlBar returns empty when totalPages <= 1', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('id', 'ID'),
        home: Scaffold(
          body: PaginationControlBar(
            currentPage: 1,
            totalPages: 1,
            totalItems: 8,
            onPageChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PaginationControlBar), findsOneWidget);
    expect(find.textContaining('Halaman'), findsNothing);
  });
}
