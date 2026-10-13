import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/core/widgets/app_card.dart';
import 'package:speech2sign/core/widgets/status_badge.dart';
import 'package:speech2sign/features/sign_language/widgets/hold_confirm_ring.dart';
import 'package:speech2sign/features/sign_language/widgets/sign_speech_card.dart';
import 'package:speech2sign/features/sign_language/widgets/widget_previews.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Custom Widgets & Design Tokens Tests', () {
    testWidgets('AppCard renders child and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Halo Dunia'),
            ),
          ),
        ),
      );

      expect(find.text('Halo Dunia'), findsOneWidget);
      await tester.tap(find.text('Halo Dunia'));
      expect(tapped, isTrue);
    });

    testWidgets('StatusBadge displays correct text and variant styles', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(label: 'BISINDO', variant: BadgeVariant.active),
                StatusBadge(label: 'Tersimpan', variant: BadgeVariant.success),
              ],
            ),
          ),
        ),
      );

      expect(find.text('BISINDO'), findsOneWidget);
      expect(find.text('Tersimpan'), findsOneWidget);
    });

    testWidgets('HoldConfirmRing renders progress within bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HoldConfirmRing(progress: 0.65, child: Icon(Icons.check)),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('SignSpeechCard responds to toggle listen callback', (
      tester,
    ) async {
      bool toggled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignSpeechCard(
              isListening: false,
              recognizedText: 'Terima kasih',
              statusText: 'Siap merekam',
              onToggleListen: () => toggled = true,
            ),
          ),
        ),
      );

      expect(find.text('Terima kasih'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic_none));
      expect(toggled, isTrue);
    });

    testWidgets('SignLanguageWidgetPreviews renders preview instances cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        SignLanguageWidgetPreviews.previewGestureCandidateLoaderSigning(),
      );
      expect(find.text('HALO'), findsOneWidget);

      await tester.pumpWidget(
        SignLanguageWidgetPreviews.previewGestureCandidateLoaderConfirmed(),
      );
      expect(find.text('TERIMA KASIH'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.pumpWidget(
        SignLanguageWidgetPreviews.previewSignVideoPlayerOnline(),
      );
      expect(find.text('Baik'), findsWidgets);

      await tester.pumpWidget(
        SignLanguageWidgetPreviews.previewSignVideoPlayerDownloading(),
      );
      expect(find.text('Mengunduh dari hajicare-sign.web.app...'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
    });
  });
}
