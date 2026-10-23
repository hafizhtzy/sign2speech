/// Type-safe string key constants for Sign2Speech application.
/// Ensures consistent key references across screens, controllers, and tests.
class AppStrings {
  AppStrings._();

  // App & General
  static const String appTitle = 'app_title';
  static const String appSubtitle = 'app_subtitle';
  static const String ok = 'ok';
  static const String cancel = 'cancel';
  static const String save = 'save';
  static const String delete = 'delete';
  static const String clear = 'clear';
  static const String copy = 'copy';
  static const String listen = 'listen';
  static const String next = 'next';
  static const String skip = 'skip';
  static const String start = 'start';
  static const String startApp = 'start_app';
  static const String startNow = 'start_now';

  // Navigation
  static const String navHome = 'nav_home';
  static const String navHistory = 'nav_history';
  static const String navLibrary = 'nav_library';
  static const String navSettings = 'nav_settings';

  // Roles & Languages
  static const String roleDeaf = 'role_deaf';
  static const String roleHearingCashier = 'role_hearing_cashier';
  static const String roleHearing = 'role_hearing';
  static const String signBisindo = 'sign_bisindo';
  static const String signSibi = 'sign_sibi';
  static const String langIndonesian = 'lang_indonesian';
  static const String langEnglish = 'lang_english';

  // Onboarding
  static const String onboarding1Title = 'onboarding_1_title';
  static const String onboarding1Desc = 'onboarding_1_desc';
  static const String onboarding2Title = 'onboarding_2_title';
  static const String onboarding2Desc = 'onboarding_2_desc';
  static const String chooseRoleTitle = 'choose_role_title';
  static const String chooseRoleSubtitle = 'choose_role_subtitle';
  static const String chooseLangTitle = 'choose_lang_title';
  static const String chooseLangSubtitle = 'choose_lang_subtitle';

  // Home Screen
  static const String homeGreeting = 'home_greeting';
  static const String homeGreetingDesc = 'home_greeting_desc';
  static const String homeCashierShortcuts = 'home_cashier_shortcuts';
  static const String homeTapToSpeak = 'home_tap_to_speak';
  static const String homeShortcutCoffee = 'home_shortcut_coffee';
  static const String homeShortcutLessIce = 'home_shortcut_less_ice';
  static const String homeShortcutLessSugar = 'home_shortcut_less_sugar';
  static const String homeMainModes = 'home_main_modes';
  static const String homeSignToSpeechBadge = 'home_sign_to_speech_badge';
  static const String homeSpeechToSignBadge = 'home_speech_to_sign_badge';
  static const String homeSignToSpeechDesc = 'home_sign_to_speech_desc';
  static const String homeSpeechToSignDesc = 'home_speech_to_sign_desc';

  // Sign to Speech (Camera)
  static const String cameraTitle = 'camera_title';
  static const String cameraInactiveTitle = 'camera_inactive_title';
  static const String cameraInactiveDesc = 'camera_inactive_desc';
  static const String cameraGestureTest = 'camera_gesture_test';
  static const String cameraDetectedText = 'camera_detected_text';
  static const String cameraAimGuide = 'camera_aim_guide';
  static const String cameraPressStartToDetect = 'camera_press_start_to_detect';
  static const String cameraReadyPerform = 'camera_ready_perform';
  static const String cameraAutoDetectActive = 'camera_auto_detect_active';
  static const String cameraManualRecord = 'camera_manual_record';
  static const String cameraSpelling = 'camera_spelling';
  static const String cameraStarting = 'camera_starting';
  static const String cameraPreparing = 'camera_preparing';
  static const String cameraFlipFront = 'camera_flip_front';
  static const String cameraFlipBack = 'camera_flip_back';
  static const String cameraStandby = 'camera_standby';
  static const String cameraLive = 'camera_live';

  // Speech to Sign
  static const String speechTitle = 'speech_title';
  static const String speechSpeakMic = 'speech_speak_mic';
  static const String speechSpeakMicDesc = 'speech_speak_mic_desc';
  static const String speechTapMicToSpeak = 'speech_tap_mic_to_speak';
  static const String speechListening = 'speech_listening';
  static const String speechReadyToRecord = 'speech_ready_to_record';
  static const String speechTrySamples = 'speech_try_samples';
  static const String speechSampleTicket = 'speech_sample_ticket';
  static const String speechSampleCoffee = 'speech_sample_coffee';
  static const String speechSampleLessSugar = 'speech_sample_less_sugar';
  static const String speechViewSignVideo = 'speech_view_sign_video';
  static const String speechResultTitle = 'speech_result_title';
  static const String speechSpokenText = 'speech_spoken_text';
  static const String speechSpeakAgain = 'speech_speak_again';
  static const String speechSavedSuccess = 'speech_saved_success';
  static const String speechOfflineBadge = 'speech_offline_badge';
  static const String speechOnlineBadge = 'speech_online_badge';
  static const String speechFallbackWarning = 'speech_fallback_warning';

  // Library
  static const String libraryTitle = 'library_title';
  static const String librarySearchPlaceholder = 'library_search_placeholder';
  static const String libraryCategoryAll = 'library_category_all';
  static const String libraryCategoryDaily = 'library_category_daily';
  static const String libraryCategoryMenu = 'library_category_menu';
  static const String libraryCategoryMeasure = 'library_category_measure';
  static const String libraryDownloadFilter = 'library_download_filter';
  static const String libraryDownloadAction = 'library_download_action';
  static const String librarySynonyms = 'library_synonyms';

  // History
  static const String historyTitle = 'history_title';
  static const String historyEmptyTitle = 'history_empty_title';
  static const String historyEmptyDesc = 'history_empty_desc';
  static const String historyStartTranslation = 'history_start_translation';
  static const String historyClearAll = 'history_clear_all';
  static const String historyConfirmClear = 'history_confirm_clear';
  static const String historyConfirmDesc = 'history_confirm_desc';

  // Settings
  static const String settingsTitle = 'settings_title';
  static const String settingsSectionPreferences = 'settings_section_preferences';
  static const String settingsAppLanguage = 'settings_app_language';
  static const String settingsAppLanguageDesc = 'settings_app_language_desc';
  static const String settingsSignLanguage = 'settings_sign_language';
  static const String settingsSignLanguageDesc = 'settings_sign_language_desc';
  static const String settingsRole = 'settings_role';
  static const String settingsRoleDesc = 'settings_role_desc';
  static const String settingsSectionTts = 'settings_section_tts';
  static const String settingsTtsSpeed = 'settings_tts_speed';
  static const String settingsTtsSpeedDesc = 'settings_tts_speed_desc';
  static const String settingsTestVoice = 'settings_test_voice';
  static const String settingsSectionVideo = 'settings_section_video';
  static const String settingsVideoSpeed = 'settings_video_speed';
  static const String settingsVideoSpeedDesc = 'settings_video_speed_desc';
  static const String settingsSectionStorage = 'settings_section_storage';
  static const String settingsOfflineStorage = 'settings_offline_storage';
  static const String settingsOfflineStorageDesc = 'settings_offline_storage_desc';
  static const String settingsClearCache = 'settings_clear_cache';
  static const String settingsCacheCleared = 'settings_cache_cleared';
}
