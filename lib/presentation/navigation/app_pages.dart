import 'package:get/get.dart';

import '../../core/constants/app_routes.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_1_screen.dart';
import '../screens/onboarding_2_screen.dart';
import '../screens/choose_role_screen.dart';
import '../screens/choose_language_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/sign_to_speech_camera_screen.dart';
import '../screens/sign_to_speech_result_screen.dart';
import '../screens/speech_to_sign_mic_screen.dart';
import '../screens/speech_to_sign_result_screen.dart';
import '../screens/sign_library_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/history_screen.dart';
import '../../features/cafe_pos/bindings/cafe_pos_binding.dart';
import '../../features/cafe_pos/screens/cafe_cashier_counter_screen.dart';
import '../../features/cafe_pos/screens/coffee_detail_screen.dart';

class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.onboarding1,
      page: () => const Onboarding1Screen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.onboarding2,
      page: () => const Onboarding2Screen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.chooseRole,
      page: () => const ChooseRoleScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.chooseLanguage,
      page: () => const ChooseLanguageScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.mainShell,
      page: () => const MainShellScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.signToSpeechCamera,
      page: () => const SignToSpeechCameraScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.signToSpeechResult,
      page: () => const SignToSpeechResultScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.speechToSignMic,
      page: () => const SpeechToSignMicScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.speechToSignResult,
      page: () => const SpeechToSignResultScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.signLibrary,
      page: () => const SignLibraryScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.history,
      page: () => const HistoryScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.cafeCashierCounter,
      page: () => const CafeCashierCounterScreen(),
      binding: CafePosBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.coffeeDetail,
      page: () => const CoffeeDetailScreen(),
      binding: CafePosBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
