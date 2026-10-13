import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const String _keyRole = 'user_selected_role';
  static const String _keySignLang = 'user_selected_sign_language';
  static const String _keyTtsSpeed = 'user_tts_speed';
  static const String _keyVideoSpeed = 'user_video_speed';
  static const String _keyOnboarded = 'has_completed_onboarding';

  final RxString selectedRole = 'Teman Tuli'.obs;
  final RxString selectedSignLanguage = 'BISINDO'.obs;
  final RxDouble ttsSpeed = 1.0.obs;
  final RxDouble videoSpeed = 1.0.obs;
  final RxBool hasCompletedOnboarding = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    selectedRole.value = prefs.getString(_keyRole) ?? 'Teman Tuli';
    selectedSignLanguage.value = prefs.getString(_keySignLang) ?? 'BISINDO';
    ttsSpeed.value = prefs.getDouble(_keyTtsSpeed) ?? 1.0;
    videoSpeed.value = prefs.getDouble(_keyVideoSpeed) ?? 1.0;
    hasCompletedOnboarding.value = prefs.getBool(_keyOnboarded) ?? false;
  }

  Future<void> setRole(String role) async {
    selectedRole.value = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role);
  }

  Future<void> setSignLanguage(String lang) async {
    selectedSignLanguage.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySignLang, lang);
  }

  Future<void> setTtsSpeed(double speed) async {
    ttsSpeed.value = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTtsSpeed, speed);
  }

  Future<void> setVideoSpeed(double speed) async {
    videoSpeed.value = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVideoSpeed, speed);
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
  }
}
