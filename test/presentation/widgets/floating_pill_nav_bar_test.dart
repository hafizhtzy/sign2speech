import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/presentation/screens/main_shell_screen.dart';
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

    testWidgets('interpolates slot widths smoothly mid-animation without instant snapping', (
      tester,
    ) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestWidget(
              currentIndex: currentIndex,
              onTap: (index) => setState(() => currentIndex = index),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      final slot0 = find.byKey(const ValueKey('nav_item_0'));
      final slot2 = find.byKey(const ValueKey('nav_item_2'));

      final initialActiveWidth = tester.getSize(slot0).width;
      final initialInactiveWidth = tester.getSize(slot2).width;
      expect(initialActiveWidth, greaterThan(initialInactiveWidth));

      // Switch to index 2 and advance 100ms (mid-flight of 340ms animation)
      await tester.tap(slot2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final midWidth0 = tester.getSize(slot0).width;
      final midWidth2 = tester.getSize(slot2).width;

      // Both slots must be smoothly transitioning between inactive & active widths
      expect(midWidth0, lessThan(initialActiveWidth));
      expect(midWidth0, greaterThan(initialInactiveWidth));
      expect(midWidth2, greaterThan(initialInactiveWidth));
      expect(midWidth2, lessThan(initialActiveWidth));

      // Settle cleanly
      await tester.pumpAndSettle();
      expect(tester.getSize(slot2).width, closeTo(initialActiveWidth, 0.5));
      expect(tester.getSize(slot0).width, closeTo(initialInactiveWidth, 0.5));
    });

    testWidgets('handles rapid mid-flight tab switching without overflow or error', (
      tester,
    ) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildTestWidget(
              currentIndex: currentIndex,
              onTap: (index) => setState(() => currentIndex = index),
              surfaceSize: const Size(320, 568),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3 -> 80ms -> Tap 1 -> 80ms -> Tap 2 -> settle
      await tester.tap(find.byKey(const ValueKey('nav_item_3')));
      await tester.pump(const Duration(milliseconds: 80));

      await tester.tap(find.byKey(const ValueKey('nav_item_1')));
      await tester.pump(const Duration(milliseconds: 80));

      await tester.tap(find.byKey(const ValueKey('nav_item_2')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Perpustakaan'), findsOneWidget);
      expect(find.text('Beranda'), findsNothing);
    });

    testWidgets('AnimatedIndexedStack preserves child State across tab switches', (
      tester,
    ) async {
      int initCount = 0;
      int currentIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: AnimatedIndexedStack(
                  index: currentIndex,
                  children: [
                    _InitCounterWidget(
                      key: const ValueKey('tab_0'),
                      onInit: () => initCount++,
                    ),
                    const SizedBox(key: ValueKey('tab_1')),
                  ],
                ),
                bottomNavigationBar: FloatingPillNavBar(
                  currentIndex: currentIndex,
                  onTap: (i) => setState(() => currentIndex = i),
                  items: testItems.take(2).toList(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(initCount, 1);

      // Switch to tab 1 and back to tab 0
      await tester.tap(find.byKey(const ValueKey('nav_item_1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav_item_0')));
      await tester.pumpAndSettle();

      // Child state must NEVER be destroyed & re-initialized on tab switch
      expect(initCount, 1);
    });
  });
}

class _InitCounterWidget extends StatefulWidget {
  final VoidCallback onInit;

  const _InitCounterWidget({super.key, required this.onInit});

  @override
  State<_InitCounterWidget> createState() => _InitCounterWidgetState();
}

class _InitCounterWidgetState extends State<_InitCounterWidget> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
