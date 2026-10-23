import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:speech2sign/core/localization/app_translations.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/cafe_order_ticket.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_menu_item.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/coffee_recommendation_result.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/dietary_alert_tag.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/order_enums.dart';
import 'package:speech2sign/features/cafe_pos/domain/models/parsed_cafe_order_slot.dart';
import 'package:speech2sign/features/cafe_pos/widgets/auto_order_slot_tray.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cafe_order_ticket_card.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cashier_quick_deck.dart';
import 'package:speech2sign/features/cafe_pos/widgets/coffee_composition_circle.dart';
import 'package:speech2sign/features/cafe_pos/widgets/coffee_recommendation_card.dart';
import 'package:speech2sign/features/cafe_pos/widgets/cup_name_spelling_card.dart';
import 'package:speech2sign/features/cafe_pos/widgets/dietary_alert_badge.dart';
import 'package:speech2sign/features/cafe_pos/widgets/dual_mode_queue_pager.dart';
import 'package:speech2sign/features/cafe_pos/widgets/order_ready_banner.dart';
import 'package:speech2sign/features/cafe_pos/widgets/waiting_sign_challenge_card.dart';

Widget _buildTestApp(Widget child, {Locale locale = const Locale('id', 'ID')}) {
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: locale,
    home: Scaffold(
      body: SingleChildScrollView(
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  group('DietaryAlertBadge Widget', () {
    testWidgets('renders warning and critical badges with expected labels', (tester) async {
      const alert = DietaryAlertTag(
        type: DietaryAlertType.lactoseIntolerant,
        severity: DietaryAlertSeverity.warning,
        labelKey: 'alert_lactose',
        defaultMessageId: 'Perhatian: Pelanggan intoleransi laktosa!',
        defaultMessageEn: 'Caution: Lactose intolerant customer!',
        detectedKeyword: 'laktosa',
      );

      await tester.pumpWidget(_buildTestApp(
        const Column(
          children: [
            DietaryAlertBadge(tag: alert, isCompact: false),
            DietaryAlertBadge(tag: alert, isCompact: true),
          ],
        ),
      ));

      expect(find.text('Perhatian: Pelanggan intoleransi laktosa!'), findsOneWidget);
      expect(find.text('LAKTOSA'), findsOneWidget);
    });
  });

  group('CoffeeCompositionCircle Widget', () {
    testWidgets('renders coffee name and 3 composition points', (tester) async {
      final item = CoffeeMenuItem.standardCatalog.first;

      await tester.pumpWidget(_buildTestApp(
        CoffeeCompositionCircle(item: item),
      ));

      expect(find.text(item.nameId), findsOneWidget);
      for (final label in item.compositionPoints) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('AutoOrderSlotTray Widget (Fitur 1 & 6)', () {
    testWidgets('renders empty placeholder when slot is null', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        AutoOrderSlotTray(
          slot: null,
          onConfirm: () {},
        ),
      ));

      expect(find.text('Draf Pesanan Otomatis'), findsOneWidget);
    });

    testWidgets('renders populated slot with chips and triggers onConfirm', (tester) async {
      bool confirmed = false;
      const slot = ParsedCafeOrderSlot(
        drinkId: 'iced_caramel_latte',
        drinkLabelKey: 'iced_caramel_latte',
        drinkNameId: 'Iced Oat Caramel Latte',
        drinkNameEn: 'Iced Oat Caramel Latte',
        basePrice: 35000,
        cupSize: OrderCupSize.large,
        temperature: OrderTemperature.iced,
        milkType: OrderMilkType.oatMilk,
        sweetnessLevel: OrderSweetnessLevel.lessSweet50,
        extraShot: true,
      );

      await tester.pumpWidget(_buildTestApp(
        AutoOrderSlotTray(
          slot: slot,
          onConfirm: () => confirmed = true,
        ),
      ));

      expect(find.text('Iced Oat Caramel Latte'), findsOneWidget);
      expect(find.text('ICED'), findsOneWidget);
      expect(find.text('LARGE'), findsOneWidget);

      final confirmBtn = find.text('Konfirmasi Masuk Nota');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      expect(confirmed, isTrue);
    });
  });

  group('CupNameSpellingCard Widget (Fitur 2)', () {
    testWidgets('renders inactive card and opens spelling mode', (tester) async {
      bool started = false;
      await tester.pumpWidget(_buildTestApp(
        CupNameSpellingCard(
          isSpelling: false,
          currentName: 'RIAN',
          buffer: '',
          remainingMs: 1500,
          onStartSpelling: () => started = true,
          onFinishSpelling: () {},
          onAddLetter: (_) {},
        ),
      ));

      expect(find.text('RIAN'), findsOneWidget);
      await tester.tap(find.text('Mode Eja Nama Aktif'));
      expect(started, isTrue);
    });

    testWidgets('renders active spelling card with countdown and letter buttons', (tester) async {
      String addedLetter = '';
      bool finished = false;

      await tester.pumpWidget(_buildTestApp(
        CupNameSpellingCard(
          isSpelling: true,
          currentName: '',
          buffer: 'RIA',
          remainingMs: 1200,
          onStartSpelling: () {},
          onFinishSpelling: () => finished = true,
          onAddLetter: (letter) => addedLetter = letter,
        ),
      ));

      expect(find.text('RIA'), findsOneWidget);
      expect(find.text('1.2s'), findsOneWidget);

      await tester.tap(find.text('N'));
      expect(addedLetter, 'N');

      await tester.tap(find.text('Selesai Eja / Spasi'));
      expect(finished, isTrue);
    });
  });

  group('CoffeeRecommendationCard Widget (Fitur 3)', () {
    testWidgets('renders AI Barista recommendation and triggers onSelect', (tester) async {
      bool selected = false;
      final item = CoffeeMenuItem.standardCatalog.first;
      final rec = CoffeeRecommendationResult(
        item: item,
        reasonId: 'Rekomendasi ramah lambung.',
        reasonEn: 'Gentle on stomach.',
        matchedTokens: const ['maag', 'rendah asam'],
        defaultOrderSlot: ParsedCafeOrderSlot(
          drinkId: item.id,
          drinkLabelKey: item.id,
          drinkNameId: item.nameId,
          drinkNameEn: item.nameEn,
          basePrice: item.basePrice,
        ),
      );

      await tester.pumpWidget(_buildTestApp(
        CoffeeRecommendationCard(
          recommendation: rec,
          onSelect: () => selected = true,
        ),
      ));

      expect(find.text(item.nameId), findsOneWidget);
      expect(find.text('Rekomendasi ramah lambung.'), findsOneWidget);
      expect(find.text('#maag'), findsOneWidget);

      await tester.tap(find.text('Pilih & Kustomisasi'));
      expect(selected, isTrue);
    });
  });

  group('CashierQuickDeck Widget (Fitur 5)', () {
    testWidgets('renders 6 barista buttons and triggers onExecute', (tester) async {
      int clickedIndex = -1;

      await tester.pumpWidget(_buildTestApp(
        CashierQuickDeck(
          activeIndex: -1,
          onExecute: (i) => clickedIndex = i,
        ),
      ));

      expect(find.byType(CashierQuickDeck), findsOneWidget);
      expect(
        find.text('Minum di sini (Dine-in) atau bawa pulang (Takeaway)?'),
        findsOneWidget,
      );
      expect(
        find.text('Untuk atas nama siapa di cup-nya?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Untuk atas nama siapa di cup-nya?'));
      expect(clickedIndex, 3);
    });
  });

  group('CafeOrderTicketCard Widget (Fitur 7)', () {
    testWidgets('renders ticket details, dashed divider, and payment options', (tester) async {
      final ticket = CafeOrderTicket(
        orderId: 'ORD-108',
        queueNumber: 'A-108',
        customerName: 'Rian',
        items: const [
          ParsedCafeOrderSlot(
            drinkId: 'cappuccino',
            drinkLabelKey: 'cappuccino',
            drinkNameId: 'Oat Cappuccino',
            drinkNameEn: 'Oat Cappuccino',
            basePrice: 30000,
            cupSize: OrderCupSize.medium,
            milkType: OrderMilkType.freshDairy,
          ),
        ],
        amountPaid: 50000,
        paymentMethod: OrderPaymentMethod.cash,
        createdAt: DateTime.now(),
      );

      bool translated = false;

      await tester.pumpWidget(_buildTestApp(
        CafeOrderTicketCard(
          ticket: ticket,
          onPaymentMethodChanged: (_) {},
          onAddCash: (_) {},
          onTranslateBill: () => translated = true,
          onClearTicket: () {},
        ),
      ));

      expect(find.text('ORD-108 • A-108'), findsOneWidget);
      expect(find.text('Rian'), findsOneWidget);
      expect(find.text('Oat Cappuccino'), findsOneWidget);
      // Grand total = 30000 + 3000 tax = 33000
      expect(find.text('Rp 33000'), findsOneWidget);
      // Change = 50000 - 33000 = 17000
      expect(find.text('Kembalian: Rp 17000'), findsOneWidget);

      await tester.tap(find.text('Terjemahkan ke Isyarat & Suara'));
      expect(translated, isTrue);
    });
  });

  group('DualModeQueuePager and OrderReadyBanner Widgets (Fitur 4)', () {
    testWidgets('DualModeQueuePager triggers hearing and deaf calls', (tester) async {
      bool calledHearing = false;
      bool calledDeaf = false;

      await tester.pumpWidget(_buildTestApp(
        DualModeQueuePager(
          queueNumber: 'A-108',
          customerName: 'Rian',
          onCallHearing: () => calledHearing = true,
          onCallDeaf: () => calledDeaf = true,
        ),
      ));

      await tester.tap(find.text('Panggil Pelanggan Dengar (FIFO TTS)'));
      expect(calledHearing, isTrue);

      await tester.tap(find.text('Panggil Pelanggan Tuli (Visual + Getar)'));
      expect(calledDeaf, isTrue);
    });

    testWidgets('OrderReadyBanner displays high-contrast visual alert', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(_buildTestApp(
        OrderReadyBanner(
          queueNumber: 'A-108',
          customerName: 'Rian',
          onDismiss: () => dismissed = true,
        ),
      ));

      expect(find.text('A-108'), findsOneWidget);
      expect(find.text('Atas nama: Rian'), findsOneWidget);
      expect(find.text('PESANAN SIAP DIAMBIL!'), findsOneWidget);

      await tester.tap(find.text('Tutup Notifikasi'));
      expect(dismissed, isTrue);
    });
  });

  group('WaitingSignChallengeCard Widget (Fitur 8)', () {
    testWidgets('renders sign word and practice button', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        WaitingSignChallengeCard(
          signWord: 'TERIMA KASIH',
          progress: 0.0,
          isCompleted: false,
          onProgressChanged: (_) {},
        ),
      ));

      expect(find.text('"TERIMA KASIH"'), findsOneWidget);
      expect(find.text('Coba Praktikkan di Kamera'), findsOneWidget);
    });
  });
}
