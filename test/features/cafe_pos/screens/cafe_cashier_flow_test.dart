import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech2sign/core/constants/app_routes.dart';
import 'package:speech2sign/main.dart';

void main() {
  testWidgets('Full flow navigation from Home to CafeCashierCounterScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;

    await tester.pumpWidget(const Sign2SpeechApp());
    await tester.pumpAndSettle();

    Get.toNamed(AppRoutes.cafeCashierCounter);
    await tester.pumpAndSettle();

    expect(find.text('Meja Kasir & Barista AI'), findsOneWidget);
  });
}
