import 'package:get/get.dart';

import 'app_strings.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'id_ID': _idID, 'en_US': _enUS};

  static final Map<String, String> _idID = {
    // App & General
    AppStrings.appTitle: 'Sign2Speech',
    AppStrings.appSubtitle: 'Aksesibilitas Kasir & Kafe',
    AppStrings.ok: 'OK',
    AppStrings.cancel: 'Batal',
    AppStrings.save: 'Simpan',
    AppStrings.delete: 'Hapus',
    AppStrings.clear: 'Bersihkan',
    AppStrings.copy: 'Salin',
    AppStrings.listen: 'Dengar',
    AppStrings.next: 'Lanjut',
    AppStrings.skip: 'Lewati',
    AppStrings.start: 'Mulai',
    AppStrings.startApp: 'Mulai Aplikasi',
    AppStrings.startNow: 'Mulai Sekarang',
    AppStrings.playVoice: 'Putar Suara',
    AppStrings.sourceText: 'Asal',
    AppStrings.originalSign: 'Isyarat',

    // Navigation
    AppStrings.navHome: 'Beranda',
    AppStrings.navHistory: 'Riwayat',
    AppStrings.navLibrary: 'Perpustakaan',
    AppStrings.navSettings: 'Pengaturan',

    // Roles & Languages
    AppStrings.roleDeaf: 'Teman Tuli',
    AppStrings.roleHearingCashier: 'Teman Dengar / Kasir',
    AppStrings.roleHearing: 'Teman Dengar',
    AppStrings.signBisindo: 'BISINDO',
    AppStrings.signSibi: 'SIBI',
    AppStrings.langIndonesian: 'Bahasa Indonesia',
    AppStrings.langEnglish: 'English',

    // Onboarding
    AppStrings.onboarding1Title: 'Komunikasi Lebih Mudah',
    AppStrings.onboarding1Desc: 'Jembatani interaksi antara Teman Tuli dan Teman Dengar secara instan dengan kecerdasan buatan saat di kafe.',
    AppStrings.onboarding2Title: 'Untuk Semua Kesempatan',
    AppStrings.onboarding2Desc: 'Memudahkan pelanggan dan barista Teman Tuli berkomunikasi saat memesan menu, memilih takaran gula/es, hingga pembayaran di kasir.',
    AppStrings.chooseRoleTitle: 'Pilih Peran Anda',
    AppStrings.chooseRoleSubtitle: 'Pilih peran yang paling sesuai untuk mempersonalisasi pengalaman Anda.',
    AppStrings.chooseLangTitle: 'Pilih Bahasa Isyarat',
    AppStrings.chooseLangSubtitle:
        'Pilih sistem isyarat utama yang ingin Anda gunakan.',

    // Home Screen
    AppStrings.homeGreeting: 'Mau Pesan Apa Hari Ini?',
    AppStrings.homeGreetingDesc: 'Pilih mode terjemahan atau pintasan kasir di bawah untuk mulai komunikasi ramah dan inklusif di kafe.',
    AppStrings.homeCashierShortcuts: 'Pintasan Kalimat Kasir',
    AppStrings.homeTapToSpeak: 'Sentuh untuk bersuara',
    AppStrings.homeShortcutCoffee: 'Pesan Kopi',
    AppStrings.homeShortcutLessIce: 'Less Ice',
    AppStrings.homeShortcutLessSugar: 'Kurang Gula',
    AppStrings.homeShortcutPayQris: 'Bayar QRIS',
    AppStrings.homeShortcutTakeaway: 'Bawa Pulang',
    AppStrings.homeCafeCatalog: 'Katalog Isyarat Kafe',
    AppStrings.homeViewAll: 'Lihat Semua',
    AppStrings.homeRecentConversation: 'Percakapan Terakhir',
    AppStrings.spokenVoiceSnackbar: 'Suara Diucapkan',
    AppStrings.homeMainModes: 'Mode Penerjemah Utama',
    AppStrings.homeSignToSpeechBadge: 'Kamera AI + Suara',
    AppStrings.homeSpeechToSignBadge: 'Mikrofon + Video',
    AppStrings.homeSignToSpeechDesc: 'Arahkan kamera ke gerakan isyarat untuk diterjemahkan menjadi suara lisan Bahasa Indonesia secara langsung.',
    AppStrings.homeSpeechToSignDesc: 'Bicara lewat mikrofon untuk menampilkan rangkaian video peragaan isyarat kata demi kata yang mudah dipahami.',

    // Sign to Speech (Camera)
    AppStrings.cameraTitle: 'Deteksi Isyarat',
    AppStrings.cameraInactiveTitle: 'Kamera Belum Aktif',
    AppStrings.cameraInactiveDesc: 'Tekan tombol MULAI di bawah untuk mengaktifkan kamera dan deteksi isyarat otomatis.',
    AppStrings.cameraGestureTest: 'Uji Coba Gestur',
    AppStrings.cameraDetectedText: 'Teks Terdeteksi',
    AppStrings.cameraAimGuide: 'Arahkan gestur ke kamera atau gunakan simulator gestur di atas untuk memulai penerjemahan...',
    AppStrings.cameraPressStartToDetect: 'Tekan MULAI untuk mendeteksi',
    AppStrings.cameraReadyPerform: 'Siap — lakukan isyarat',
    AppStrings.cameraAutoDetectActive: 'Deteksi gestur otomatis aktif',
    AppStrings.cameraManualRecord: 'Rekam Manual',
    AppStrings.cameraSpelling: 'Mengeja',
    AppStrings.cameraStarting: 'Mengaktifkan Kamera...',
    AppStrings.cameraPreparing: 'Menyiapkan sensor dan izin kamera',
    AppStrings.cameraFlipFront: 'Depan',
    AppStrings.cameraFlipBack: 'Belakang',
    AppStrings.cameraStandby: 'STANDBY',
    AppStrings.cameraLive: 'LIVE',

    // Speech to Sign
    AppStrings.speechTitle: 'Speech to Sign',
    AppStrings.speechSpeakMic: 'Bicara Lewat Mikrofon',
    AppStrings.speechSpeakMicDesc: 'Ucapkan kalimat dalam Bahasa Indonesia. Sistem akan mencocokkan kata dengan peragaan video isyarat.',
    AppStrings.speechTapMicToSpeak: 'Tekan mikrofon untuk bicara',
    AppStrings.speechListening: 'Mendengarkan ucapan Anda...',
    AppStrings.speechReadyToRecord: 'Siap merekam suara',
    AppStrings.speechTrySamples: 'Atau coba contoh ucapan langsung:',
    AppStrings.speechSampleTicket: 'Saya mau beli tiket',
    AppStrings.speechSampleCoffee: 'Pesan kopi satu',
    AppStrings.speechSampleLessSugar: 'Kurang gula',
    AppStrings.speechViewSignVideo: 'Lihat Peragaan Isyarat',
    AppStrings.speechResultTitle: 'Hasil Speech to Sign',
    AppStrings.speechSpokenText: 'Teks Ucapan:',
    AppStrings.speechSpeakAgain: 'Bicara Lagi',
    AppStrings.speechSavedSuccess: 'Berhasil disimpan ke riwayat percakapan',
    AppStrings.speechOfflineBadge: 'Video Offline',
    AppStrings.speechOnlineBadge: 'Video Online',
    AppStrings.speechFallbackWarning: 'Kata ini tidak ditemukan di bahasa isyarat terpilih. Menampilkan alternatif dari sistem isyarat lain.',

    // Library
    AppStrings.libraryTitle: 'Perpustakaan Isyarat',
    AppStrings.librarySearchPlaceholder:
        'Cari menu, kata, huruf, atau sinonim...',
    AppStrings.libraryCategoryAll: 'Semua',
    AppStrings.libraryCategoryDaily: 'Harian',
    AppStrings.libraryCategoryMenu: 'Minuman & Menu',
    AppStrings.libraryCategoryMeasure: 'Takaran',
    AppStrings.libraryDownloadFilter: 'Unduh Filter Ini',
    AppStrings.libraryDownloadAction: 'Unduh',
    AppStrings.librarySynonyms: 'Sinonim',

    // History
    AppStrings.historyTitle: 'Riwayat Percakapan',
    AppStrings.historyEmptyTitle: 'Belum Ada Riwayat',
    AppStrings.historyEmptyDesc: 'Mulai terjemahan lewat kamera atau mikrofon untuk menyimpan riwayat percakapan.',
    AppStrings.historyStartTranslation: 'Mulai Terjemahan',
    AppStrings.historyClearAll: 'Hapus Semua Riwayat',
    AppStrings.historyConfirmClear: 'Hapus Riwayat?',
    AppStrings.historyConfirmDesc:
        'Semua catatan percakapan yang tersimpan akan dihapus secara permanen.',

    // Settings
    AppStrings.settingsTitle: 'Pengaturan',
    AppStrings.settingsSectionPreferences: 'Preferensi Bahasa & Peran',
    AppStrings.settingsAppLanguage: 'Bahasa Aplikasi',
    AppStrings.settingsAppLanguageDesc: 'Pilih bahasa tampilan antarmuka',
    AppStrings.settingsSignLanguage: 'Bahasa Isyarat Aktif',
    AppStrings.settingsSignLanguageDesc:
        'Pilih sistem pengenalan & peragaan isyarat',
    AppStrings.settingsRole: 'Peran Komunikasi',
    AppStrings.settingsRoleDesc: 'Sesuaikan pengalaman interaksi',
    AppStrings.settingsSectionTts: 'Suara & Audio TTS (id-ID)',
    AppStrings.settingsTtsSpeed: 'Kecepatan Ucapan Suara',
    AppStrings.settingsTtsSpeedDesc:
        'Mengatur kelancaran tempo suara Text-to-Speech',
    AppStrings.settingsTestVoice: 'Uji Coba Suara',
    AppStrings.settingsSectionVideo: 'Video Peragaan Isyarat',
    AppStrings.settingsVideoSpeed: 'Kecepatan Default Video',
    AppStrings.settingsVideoSpeedDesc:
        'Kelajuan pemutaran animasi gerakan isyarat',
    AppStrings.settingsSectionStorage: 'Penyimpanan & Cache',
    AppStrings.settingsOfflineStorage: 'Penyimpanan Offline',
    AppStrings.settingsOfflineStorageDesc: 'Video kosakata inti tersedia langsung di dalam aplikasi tanpa kuota internet.',
    AppStrings.settingsClearCache: 'Bersihkan Cache Video Lokal',
    AppStrings.settingsCacheCleared: 'Cache video lokal berhasil dibersihkan',
    AppStrings.settingsThemeMode: 'Tema Tampilan',
    AppStrings.settingsThemeModeDesc: 'Pilih tampilan terang atau gelap (Instagram AMOLED)',
    AppStrings.themeModeSystem: 'Ikuti Sistem',
    AppStrings.themeModeLight: 'Terang (Cafe Cream)',
    AppStrings.themeModeDark: 'Gelap (Instagram)',

    // Cashier & Customer Assistant
    AppStrings.cashierAssistantTitle: 'Alat Kasir & Belanja',
    AppStrings.cashierAssistantSubtitle: 'Komunikasi Ramah di Meja Kasir',
    AppStrings.cashierTabPresets: 'Pintasan Kafe',
    AppStrings.cashierTabPricePad: 'Ketik Nominal',
    AppStrings.cashierTabCustomerDisplay: 'Layar Hadap Lawan',
    AppStrings.cashierPresetsMenu: 'Menu & Minuman',
    AppStrings.cashierPresetsPayment: 'Metode Pembayaran',
    AppStrings.cashierPresetsFriendly: 'Sapaan & Bantuan',
    AppStrings.cashierSpeakAmount: 'Ucapkan Nominal Suara',
    AppStrings.cashierAmountPrompt: 'Masukkan nominal total pesanan:',
    AppStrings.cashierClearAmount: 'Hapus',
    AppStrings.cashierFlipScreen: 'Balik Layar 180°',
    AppStrings.cashierFlipScreenDesc: 'Putar tampilan agar mudah dibaca oleh orang di seberang meja kasir',
    AppStrings.cashierCustomerViewBadge: 'Tampilan Kasir & Pelanggan',
    AppStrings.cashierOpenAssistant: 'Buka Alat Kasir & Belanja',

    // Onboarding 3
    AppStrings.onboarding3Title: 'Alat Kasir Pintar & Mode Balik Layar',
    AppStrings.onboarding3Desc: 'Lengkap dengan papan nominal rupiah instan, pintasan pesanan kafe, dan layar yang bisa dibalik 180° menghadap lawan bicara.',
    AppStrings.onboardingBadgePresets: 'Papan Nominal Cepat',
    AppStrings.onboardingBadgeFlipScreen: 'Layar Balik Hadap Lawan',
  };

  static final Map<String, String> _enUS = {
    // App & General
    AppStrings.appTitle: 'Sign2Speech',
    AppStrings.appSubtitle: 'Cashier & Cafe Accessibility',
    AppStrings.ok: 'OK',
    AppStrings.cancel: 'Cancel',
    AppStrings.save: 'Save',
    AppStrings.delete: 'Delete',
    AppStrings.clear: 'Clear',
    AppStrings.copy: 'Copy',
    AppStrings.listen: 'Listen',
    AppStrings.next: 'Next',
    AppStrings.skip: 'Skip',
    AppStrings.start: 'Start',
    AppStrings.startApp: 'Start Application',
    AppStrings.startNow: 'Start Now',
    AppStrings.playVoice: 'Play Voice',
    AppStrings.sourceText: 'Source',
    AppStrings.originalSign: 'Sign',

    // Navigation
    AppStrings.navHome: 'Home',
    AppStrings.navHistory: 'History',
    AppStrings.navLibrary: 'Library',
    AppStrings.navSettings: 'Settings',

    // Roles & Languages
    AppStrings.roleDeaf: 'Deaf Friend',
    AppStrings.roleHearingCashier: 'Hearing Friend / Cashier',
    AppStrings.roleHearing: 'Hearing Friend',
    AppStrings.signBisindo: 'BISINDO',
    AppStrings.signSibi: 'SIBI',
    AppStrings.langIndonesian: 'Bahasa Indonesia',
    AppStrings.langEnglish: 'English',

    // Onboarding
    AppStrings.onboarding1Title:
        'Inclusive Communication in Cafes & Public Places',
    AppStrings.onboarding1Desc: 'Instantly bridge interaction between Deaf and Hearing friends with artificial intelligence.',
    AppStrings.onboarding2Title: 'Two-Way: Sign to Speech, Speech to Sign',
    AppStrings.onboarding2Desc: 'Translate BISINDO & SIBI sign language into spoken voice, and turn speech into sign language video demonstrations.',
    AppStrings.chooseRoleTitle: 'Choose Your Role',
    AppStrings.chooseRoleSubtitle:
        'Choose the role that best fits to personalize your experience.',
    AppStrings.chooseLangTitle: 'Choose Sign Language',
    AppStrings.chooseLangSubtitle:
        'Select the primary sign system you wish to use.',

    // Home Screen
    AppStrings.homeGreeting: 'What Would You Like to Order Today?',
    AppStrings.homeGreetingDesc: 'Choose a translation mode or cashier shortcut below to start friendly and inclusive communication.',
    AppStrings.homeCashierShortcuts: 'Cashier Sentence Shortcuts',
    AppStrings.homeTapToSpeak: 'Tap to speak',
    AppStrings.homeShortcutCoffee: 'Order Coffee',
    AppStrings.homeShortcutLessIce: 'Less Ice',
    AppStrings.homeShortcutLessSugar: 'Less Sugar',
    AppStrings.homeShortcutPayQris: 'Pay with QRIS',
    AppStrings.homeShortcutTakeaway: 'Takeaway',
    AppStrings.homeCafeCatalog: 'Cafe Sign Catalog',
    AppStrings.homeViewAll: 'View All',
    AppStrings.homeRecentConversation: 'Recent Conversations',
    AppStrings.spokenVoiceSnackbar: 'Spoken Voice',
    AppStrings.homeMainModes: 'Main Translator Modes',
    AppStrings.homeSignToSpeechBadge: 'AI Camera + Voice',
    AppStrings.homeSpeechToSignBadge: 'Microphone + Video',
    AppStrings.homeSignToSpeechDesc: 'Point camera at sign gestures to translate into spoken voice in real time.',
    AppStrings.homeSpeechToSignDesc: 'Speak through the microphone to view step-by-step sign language video demonstrations.',

    // Sign to Speech (Camera)
    AppStrings.cameraTitle: 'Sign Detection',
    AppStrings.cameraInactiveTitle: 'Camera Not Active',
    AppStrings.cameraInactiveDesc: 'Press START below to activate camera and automatic sign gesture detection.',
    AppStrings.cameraGestureTest: 'Test Gestures',
    AppStrings.cameraDetectedText: 'Detected Text',
    AppStrings.cameraAimGuide: 'Point gestures to camera or use simulator above to start translation...',
    AppStrings.cameraPressStartToDetect: 'Press START to detect',
    AppStrings.cameraReadyPerform: 'Ready — perform sign gesture',
    AppStrings.cameraAutoDetectActive: 'Automatic gesture detection active',
    AppStrings.cameraManualRecord: 'Manual Record',
    AppStrings.cameraSpelling: 'Spelling',
    AppStrings.cameraStarting: 'Starting Camera...',
    AppStrings.cameraPreparing: 'Preparing camera sensors and permissions',
    AppStrings.cameraFlipFront: 'Front',
    AppStrings.cameraFlipBack: 'Back',
    AppStrings.cameraStandby: 'STANDBY',
    AppStrings.cameraLive: 'LIVE',

    // Speech to Sign
    AppStrings.speechTitle: 'Speech to Sign',
    AppStrings.speechSpeakMic: 'Speak via Microphone',
    AppStrings.speechSpeakMicDesc: 'Speak your sentence. The system matches spoken words with sign language video demonstrations.',
    AppStrings.speechTapMicToSpeak: 'Tap microphone to speak',
    AppStrings.speechListening: 'Listening to your voice...',
    AppStrings.speechReadyToRecord: 'Ready to record voice',
    AppStrings.speechTrySamples: 'Or try sample phrases:',
    AppStrings.speechSampleTicket: 'I want to buy a ticket',
    AppStrings.speechSampleCoffee: 'One cup of coffee please',
    AppStrings.speechSampleLessSugar: 'Less sugar please',
    AppStrings.speechViewSignVideo: 'View Sign Demonstration',
    AppStrings.speechResultTitle: 'Speech to Sign Result',
    AppStrings.speechSpokenText: 'Spoken Text:',
    AppStrings.speechSpeakAgain: 'Speak Again',
    AppStrings.speechSavedSuccess: 'Successfully saved to conversation history',
    AppStrings.speechOfflineBadge: 'Offline Video',
    AppStrings.speechOnlineBadge: 'Online Video',
    AppStrings.speechFallbackWarning: 'This word was not found in selected sign language. Showing alternative from other sign system.',

    // Library
    AppStrings.libraryTitle: 'Sign Library',
    AppStrings.librarySearchPlaceholder:
        'Search menu, words, letters, or synonyms...',
    AppStrings.libraryCategoryAll: 'All',
    AppStrings.libraryCategoryDaily: 'Daily',
    AppStrings.libraryCategoryMenu: 'Drinks & Menu',
    AppStrings.libraryCategoryMeasure: 'Portions',
    AppStrings.libraryDownloadFilter: 'Download This Filter',
    AppStrings.libraryDownloadAction: 'Download',
    AppStrings.librarySynonyms: 'Synonyms',

    // History
    AppStrings.historyTitle: 'Conversation History',
    AppStrings.historyEmptyTitle: 'No History Yet',
    AppStrings.historyEmptyDesc: 'Start translation via camera or microphone to save conversation history.',
    AppStrings.historyStartTranslation: 'Start Translation',
    AppStrings.historyClearAll: 'Clear All History',
    AppStrings.historyConfirmClear: 'Clear History?',
    AppStrings.historyConfirmDesc:
        'All saved conversation notes will be deleted permanently.',

    // Settings
    AppStrings.settingsTitle: 'Settings',
    AppStrings.settingsSectionPreferences: 'Language & Role Preferences',
    AppStrings.settingsAppLanguage: 'App Language',
    AppStrings.settingsAppLanguageDesc: 'Choose interface display language',
    AppStrings.settingsSignLanguage: 'Active Sign Language',
    AppStrings.settingsSignLanguageDesc:
        'Select sign recognition & demonstration system',
    AppStrings.settingsRole: 'Communication Role',
    AppStrings.settingsRoleDesc: 'Customize interaction experience',
    AppStrings.settingsSectionTts: 'TTS Voice & Audio',
    AppStrings.settingsTtsSpeed: 'Voice Speech Rate',
    AppStrings.settingsTtsSpeedDesc:
        'Adjust pacing and speed of Text-to-Speech audio',
    AppStrings.settingsTestVoice: 'Test Voice',
    AppStrings.settingsSectionVideo: 'Sign Demonstration Video',
    AppStrings.settingsVideoSpeed: 'Default Video Speed',
    AppStrings.settingsVideoSpeedDesc:
        'Playback rate for sign language demonstrations',
    AppStrings.settingsSectionStorage: 'Storage & Cache',
    AppStrings.settingsOfflineStorage: 'Offline Storage',
    AppStrings.settingsOfflineStorageDesc: 'Core vocabulary videos available offline inside the app without mobile data.',
    AppStrings.settingsClearCache: 'Clear Local Video Cache',
    AppStrings.settingsCacheCleared: 'Local video cache cleared successfully',
    AppStrings.settingsThemeMode: 'Display Theme',
    AppStrings.settingsThemeModeDesc: 'Choose Light or Dark (Instagram AMOLED) mode',
    AppStrings.themeModeSystem: 'System Default',
    AppStrings.themeModeLight: 'Light (Cafe Cream)',
    AppStrings.themeModeDark: 'Dark (Instagram)',

    // Cashier & Customer Assistant
    AppStrings.cashierAssistantTitle: 'Cashier & Shopping Assistant',
    AppStrings.cashierAssistantSubtitle: 'Friendly Communication at the Counter',
    AppStrings.cashierTabPresets: 'Cafe Presets',
    AppStrings.cashierTabPricePad: 'Price Pad',
    AppStrings.cashierTabCustomerDisplay: 'Facing Display',
    AppStrings.cashierPresetsMenu: 'Menu & Drinks',
    AppStrings.cashierPresetsPayment: 'Payment Methods',
    AppStrings.cashierPresetsFriendly: 'Greetings & Assistance',
    AppStrings.cashierSpeakAmount: 'Speak Spoken Amount',
    AppStrings.cashierAmountPrompt: 'Enter order total amount:',
    AppStrings.cashierClearAmount: 'Clear',
    AppStrings.cashierFlipScreen: 'Flip Screen 180°',
    AppStrings.cashierFlipScreenDesc: 'Rotate screen so person across the counter can read effortlessly',
    AppStrings.cashierCustomerViewBadge: 'Cashier & Customer Display',
    AppStrings.cashierOpenAssistant: 'Open Cashier Assistant',

    // Onboarding 3
    AppStrings.onboarding3Title: 'Smart Cashier Tools & Flip Display',
    AppStrings.onboarding3Desc: 'Equipped with instant price numpad, cafe order presets, and 180° flip display facing the person across the counter.',
    AppStrings.onboardingBadgePresets: 'Quick Price Pad',
    AppStrings.onboardingBadgeFlipScreen: '180° Facing Display',
  };
}
