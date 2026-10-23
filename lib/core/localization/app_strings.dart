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
  static const String playVoice = 'play_voice';
  static const String sourceText = 'source_text';
  static const String originalSign = 'original_sign';

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
  static const String homeShortcutPayQris = 'home_shortcut_pay_qris';
  static const String homeShortcutTakeaway = 'home_shortcut_takeaway';
  static const String homeCafeCatalog = 'home_cafe_catalog';
  static const String homeViewAll = 'home_view_all';
  static const String homeRecentConversation = 'home_recent_conversation';
  static const String spokenVoiceSnackbar = 'spoken_voice_snackbar';
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
  static const String libraryNoVideosToDownload = 'library_no_videos_to_download';
  static const String libraryNoVideosToDownloadDesc = 'library_no_videos_to_download_desc';
  static const String libraryDownloadComplete = 'library_download_complete';
  static const String libraryDownloadCompleteDesc = 'library_download_complete_desc';
  static const String pkgDownloadSuccess = 'pkg_download_success';
  static const String pkgDownloadSuccessDesc = 'pkg_download_success_desc';
  static const String pkgDownloadCancelled = 'pkg_download_cancelled';
  static const String pkgDownloadCancelledDesc = 'pkg_download_cancelled_desc';
  static const String pkgDownloadFailed = 'pkg_download_failed';
  static const String pkgDownloadFailedDesc = 'pkg_download_failed_desc';
  static const String pkgCleanSuccess = 'pkg_clean_success';
  static const String pkgCleanSuccessDesc = 'pkg_clean_success_desc';

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
  static const String settingsThemeMode = 'settings_theme_mode';
  static const String settingsThemeModeDesc = 'settings_theme_mode_desc';
  static const String themeModeSystem = 'theme_mode_system';
  static const String themeModeLight = 'theme_mode_light';
  static const String themeModeDark = 'theme_mode_dark';

  // Cashier & Customer Assistant
  static const String cashierAssistantTitle = 'cashier_assistant_title';
  static const String cashierAssistantSubtitle = 'cashier_assistant_subtitle';
  static const String cashierTabPresets = 'cashier_tab_presets';
  static const String cashierTabPricePad = 'cashier_tab_price_pad';
  static const String cashierTabCustomerDisplay = 'cashier_tab_customer_display';
  static const String cashierPresetsMenu = 'cashier_presets_menu';
  static const String cashierPresetsPayment = 'cashier_presets_payment';
  static const String cashierPresetsFriendly = 'cashier_presets_friendly';
  static const String cashierSpeakAmount = 'cashier_speak_amount';
  static const String cashierAmountPrompt = 'cashier_amount_prompt';
  static const String cashierClearAmount = 'cashier_clear_amount';
  static const String cashierFlipScreen = 'cashier_flip_screen';
  static const String cashierFlipScreenDesc = 'cashier_flip_screen_desc';
  static const String cashierCustomerViewBadge = 'cashier_customer_view_badge';
  static const String cashierOpenAssistant = 'cashier_open_assistant';

  // Onboarding 3
  static const String onboarding3Title = 'onboarding_3_title';
  static const String onboarding3Desc = 'onboarding_3_desc';
  static const String onboardingBadgePresets = 'onboarding_badge_presets';
  static const String onboardingBadgeFlipScreen = 'onboarding_badge_flip_screen';

  // Sign to Speech Result
  static const String signResultTitle = 'sign_result_title';
  static const String signResultOriginalSign = 'sign_result_original_sign';
  static const String signResultPlayVoice = 'sign_result_play_voice';
  static const String signResultCopyText = 'sign_result_copy_text';
  static const String signResultCopied = 'sign_result_copied';
  static const String signResultCopiedDesc = 'sign_result_copied_desc';
  static const String signResultSaveHistory = 'sign_result_save_history';
  static const String signResultSaved = 'sign_result_saved';
  static const String signResultSavedDesc = 'sign_result_saved_desc';
  static const String signResultBackToCamera = 'sign_result_back_to_camera';

  // Cafe POS & 8 Killer Features
  static const String cafeAutoOrderTitle = 'cafe_auto_order_title';
  static const String cafeAutoOrderSubtitle = 'cafe_auto_order_subtitle';
  static const String cafeConfirmToTicket = 'cafe_confirm_to_ticket';
  static const String cafeParsedSlotDetected = 'cafe_parsed_slot_detected';
  static const String cafeModifierExtraShot = 'cafe_modifier_extra_shot';

  static const String cafeCupNameTitle = 'cafe_cup_name_title';
  static const String cafeCupNameSubtitle = 'cafe_cup_name_subtitle';
  static const String cafeCupNameActive = 'cafe_cup_name_active';
  static const String cafeCupNameFinish = 'cafe_cup_name_finish';
  static const String cafeCupNameFor = 'cafe_cup_name_for';

  static const String cafeAiSommelierTitle = 'cafe_ai_sommelier_title';
  static const String cafeAiSommelierSubtitle = 'cafe_ai_sommelier_subtitle';
  static const String cafeAiChooseCustomize = 'cafe_ai_choose_customize';
  static const String cafeAiMatchedReason = 'cafe_ai_matched_reason';

  static const String cafeQueuePagerTitle = 'cafe_queue_pager_title';
  static const String cafeCallHearing = 'cafe_call_hearing';
  static const String cafeCallDeaf = 'cafe_call_deaf';
  static const String cafeOrderReady = 'cafe_order_ready';
  static const String cafeOrderReadyDesc = 'cafe_order_ready_desc';

  static const String cafeQuickDeckTitle = 'cafe_quick_deck_title';
  static const String cafeQuickDeckSubtitle = 'cafe_quick_deck_subtitle';
  static const String quickDeck1 = 'quick_deck_1';
  static const String quickDeck2 = 'quick_deck_2';
  static const String quickDeck3 = 'quick_deck_3';
  static const String quickDeck4 = 'quick_deck_4';
  static const String quickDeck5 = 'quick_deck_5';
  static const String quickDeck6 = 'quick_deck_6';

  static const String cafeDietaryAlertTitle = 'cafe_dietary_alert_title';
  static const String alertLactose = 'alert_lactose';
  static const String alertDiabetes = 'alert_diabetes';
  static const String alertNut = 'alert_nut';
  static const String alertDairy = 'alert_dairy';
  static const String alertMaag = 'alert_maag';

  static const String cafeTicketTitle = 'cafe_ticket_title';
  static const String cafeSubtotal = 'cafe_subtotal';
  static const String cafeTax = 'cafe_tax';
  static const String cafeGrandTotal = 'cafe_grand_total';
  static const String cafePaymentQris = 'cafe_payment_qris';
  static const String cafePaymentCash = 'cafe_payment_cash';
  static const String cafeAmountReceived = 'cafe_amount_received';
  static const String cafeChange = 'cafe_change';
  static const String cafeTranslateBill = 'cafe_translate_bill';

  static const String cafeWaitingChallengeTitle = 'cafe_waiting_challenge_title';
  static const String cafeWaitingChallengeDesc = 'cafe_waiting_challenge_desc';
  static const String cafeTryCamera = 'cafe_try_camera';
  static const String cafeChallengeSuccess = 'cafe_challenge_success';
  static const String cafeHoldGuide = 'cafe_hold_guide';

  static const String cafeCoffeeDetailTitle = 'cafe_coffee_detail_title';
  static const String cafeSendToCashier = 'cafe_send_to_cashier';
  static const String cafeDualViewCustomer = 'cafe_dual_view_customer';
  static const String cafeDualViewCashier = 'cafe_dual_view_cashier';
  static const String cafeQueueNumber = 'cafe_queue_number';
  static const String cafeCompositionOat = 'cafe_composition_oat';
  static const String cafeCompositionFoam = 'cafe_composition_foam';
  static const String cafeCompositionEspresso = 'cafe_composition_espresso';

  // Live Camera & Interactive Real-Time POS
  static const String cafeLiveOrderCameraTitle = 'cafe_live_order_camera_title';
  static const String cafeLiveOrderCameraHint = 'cafe_live_order_camera_hint';
  static const String cafeSpellingCameraTitle = 'cafe_spelling_camera_title';
  static const String cafeSpellingCameraHint = 'cafe_spelling_camera_hint';
  static const String cafeChallengeHintBtn = 'cafe_challenge_hint_btn';
  static const String cafeChallengeCloseCamera = 'cafe_challenge_close_camera';
  static const String cafeSwitchCamera = 'cafe_switch_camera';
  static const String cafeDetectedLetter = 'cafe_detected_letter';
  static const String cafeHoldConfirming = 'cafe_hold_confirming';
  static const String cafeCameraActive = 'cafe_camera_active';
  static const String cafeOpenLiveCamera = 'cafe_open_live_camera';
  static const String cafeCloseLiveCamera = 'cafe_close_live_camera';
  static const String cafeDeleteOrderTitle = 'cafe_delete_order_title';
  static const String cafeDeleteOrderConfirm = 'cafe_delete_order_confirm';
  static const String cafeDeleteItem = 'cafe_delete_item';
  static const String cafeForCustomerName = 'cafe_for_customer_name';
  static const String cafeSignVideoReady = 'cafe_sign_video_ready';
  static const String cafeCloseNotification = 'cafe_close_notification';
  static const String cafeTrophyTitle = 'cafe_trophy_title';
  static const String cafeTrophyDesc = 'cafe_trophy_desc';
  static const String cafeTrophyAction = 'cafe_trophy_action';

  static const String cafeEmptyTicket = 'cafe_empty_ticket';
  static const String cafeCustomerNotesPrefix = 'cafe_customer_notes_prefix';
  static const String cafeSubstituteOatMilk = 'cafe_substitute_oat_milk';
  static const String cafeExactCash = 'cafe_exact_cash';
  static const String cafeCompleteCashPayment = 'cafe_complete_cash_payment';
  static const String cafeQrisNationalStandard = 'cafe_qris_national_standard';
  static const String cafeQrisVerifying = 'cafe_qris_verifying';
  static const String cafeQrisSimulatePay = 'cafe_qris_simulate_pay';
  static const String cafePaymentSuccessServing = 'cafe_payment_success_serving';
  static const String cafeResetTicketTooltip = 'cafe_reset_ticket_tooltip';
  static const String cafeTranscriptInputHint = 'cafe_transcript_input_hint';
  static const String cafeProcessOrder = 'cafe_process_order';
  static const String cafeListeningVoiceNow = 'cafe_listening_voice_now';
  static const String cafeSimulatorTranscriptTitle = 'cafe_simulator_transcript_title';
  static const String cafeQuickExamples = 'cafe_quick_examples';
  static const String cafeDetectedPrefix = 'cafe_detected_prefix';
  static const String cafeQuickOrderAction = 'cafe_quick_order_action';
  static const String cafeCameraListeningGestures = 'cafe_camera_listening_gestures';
  static const String cafeOpenMenuCatalog = 'cafe_open_menu_catalog';

  static const String cafeSignGuideTitle = 'cafe_sign_guide_title';
  static const String cafeReadyToPractice = 'cafe_ready_to_practice';
  static const String cafeChangeSignTooltip = 'cafe_change_sign_tooltip';
  static const String cafeChallengeTitle = 'cafe_challenge_title';
  static const String cafeMatchPercentage = 'cafe_match_percentage';
  static const String cafeTodaySignTitle = 'cafe_today_sign_title';
  static const String cafeAimGestureHint = 'cafe_aim_gesture_hint';
  static const String cafeTryAgain = 'cafe_try_again';
  static const String cafeHoldForLetter = 'cafe_hold_for_letter';
  static const String cafeTouchToSpell = 'cafe_touch_to_spell';
  static const String cafeDeleteLastLetter = 'cafe_delete_last_letter';
  static const String cafeOfficialReceipt = 'cafe_official_receipt';
  static const String cafeSelect = 'cafe_select';
  static const String cashierGreetingPrompt = 'cashier_greeting_prompt';
  static const String cashierScreenNormal = 'cashier_screen_normal';
  static const String cashierSpeakThisText = 'cashier_speak_this_text';
  static const String cafeSpellingHintUnlimited = 'cafe_spelling_hint_unlimited';
  static const String cafeCashierBaristaAiTitle = 'cafe_cashier_barista_ai_title';
  static const String cafeQueueNumberPrefix = 'cafe_queue_number_prefix';
  static const String cafeClearTicketTooltip = 'cafe_clear_ticket_tooltip';
  static const String cafeBackTooltip = 'cafe_back_tooltip';
}

