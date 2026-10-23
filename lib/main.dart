import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_routes.dart';
import 'core/localization/app_translations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_binding.dart';
import 'presentation/navigation/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load user saved language & theme preferences before running app
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('pref_app_lang') ?? 'id';
  final initialLocale = savedLang == 'en'
      ? const Locale('en', 'US')
      : const Locale('id', 'ID');

  final savedTheme = prefs.getString('user_selected_theme_mode') ?? 'system';
  final initialThemeMode = savedTheme == 'light'
      ? ThemeMode.light
      : savedTheme == 'dark'
      ? ThemeMode.dark
      : ThemeMode.system;

  // Android 15 & modern iOS edge-to-edge system UI overlay style
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final isDarkSystem = initialThemeMode == ThemeMode.dark;
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkSystem
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDarkSystem
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(
    Sign2SpeechApp(
      initialLocale: initialLocale,
      initialThemeMode: initialThemeMode,
    ),
  );
}

class Sign2SpeechApp extends StatelessWidget {
  final Locale initialLocale;
  final ThemeMode initialThemeMode;

  const Sign2SpeechApp({
    super.key,
    this.initialLocale = const Locale('id', 'ID'),
    this.initialThemeMode = ThemeMode.system,
  });

  @override
  Widget build(BuildContext context) {
    AppTranslations.ensureLoaded();
    return GetMaterialApp(
      title: 'Sign2Speech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: initialThemeMode,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Global dynamic textScaler protection against extreme OS font zoom overflows
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.25),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
