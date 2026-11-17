import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/presentation/widgets/floating_pill_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testItems = [
    const FloatingPillNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Beranda',
    ),
    const FloatingPillNavItem(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      label: 'Riwayat',
    ),
    const FloatingPillNavItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'Perpustakaan',
    ),
    const FloatingPillNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Pengaturan',
    ),
  ];

  Widget buildTestWidget({
    required int currentIndex,
    required ValueChanged<int> onTap,
    Size surfaceSize = const Size(360, 640),
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: FloatingPillNavBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: testItems,
          ),
        ),
      ),
    );
  }

  group('FloatingPillNavBar Widget Tests', () {
    testWidgets('renders active item with label and inactive items as icons only', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 0,
          onTap: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Active item (Beranda) shows label
      expect(find.text('Beranda'), findsOneWidget);

      // Inactive items do not show label text in widget tree
      expect(find.text('Riwayat'), findsNothing);
      expect(find.text('Perpustakaan'), findsNothing);
      expect(find.text('Pengaturan'), findsNothing);

      // But all icons are present
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.history_outlined), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('tapping an inactive item fires onTap with correct index', (
      tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 0,
          onTap: (index) => tappedIndex = index,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on History item (index 1)
      await tester.tap(find.byIcon(Icons.history_outlined));
      expect(tappedIndex, 1);

      // Tap on Settings item (index 3)
      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(tappedIndex, 3);
    });

    testWidgets('active item does not fire onTap when tapped again', (
      tester,
    ) async {
      int tapCount = 0;

      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 0,
          onTap: (_) => tapCount++,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on already active item (Home)
      await tester.tap(find.byIcon(Icons.home_rounded));
      expect(tapCount, 0);
    });

    testWidgets('renders without overflow on narrow 320x568 screen with long active label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Index 2 is 'Perpustakaan' (12 characters)
      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 2,
          onTap: (_) {},
          surfaceSize: const Size(320, 568),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Perpustakaan'), findsOneWidget);
    });

    testWidgets('all nav items meet minimum touch target >= 48x48 dp', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 0,
          onTap: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Find all GestureDetectors inside FloatingPillNavBar
      final gestureFinders = find.descendant(
        of: find.byType(FloatingPillNavBar),
        matching: find.byType(GestureDetector),
      );

      expect(gestureFinders, findsNWidgets(4));

      for (int i = 0; i < 4; i++) {
        final size = tester.getSize(gestureFinders.at(i));
        expect(size.width, greaterThanOrEqualTo(48.0));
        expect(size.height, greaterThanOrEqualTo(48.0));
      }
    });
  });
}
