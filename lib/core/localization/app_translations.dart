import 'package:get/get.dart';

import 'app_strings.dart';

class AppTranslations extends Translations {
  /// Ensures that GetX's translation table has all dictionaries dynamically loaded,
  /// including both full locale keys ('id_ID', 'en_US') and language-only codes ('id', 'en').
  static void ensureLoaded() {
    Get.appendTranslations(AppTranslations().keys);
  }

  @override
  Map<String, Map<String, String>> get keys => {
    'id_ID': _idID,
    'id': _idID,
    'en_US': _enUS,
    'en': _enUS,
  };

  static Map<String, String> get _idID => {
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
    AppStrings.previous: 'Sebelumnya',
    AppStrings.paginationShowing: 'Menampilkan @start-@end dari @total kosakata',
    AppStrings.paginationPageOf: 'Halaman @page dari @total',
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
    AppStrings.onboarding1Title: 'Komunikasi Lebih Mudah & Inklusif',
    AppStrings.onboarding1Desc:
        'Jembatani interaksi antara Teman Tuli dan Teman Dengar secara instan dengan kecerdasan buatan saat di kafe.',
    AppStrings.onboarding2Title: 'Deteksi Isyarat AI & Suara Lisan',
    AppStrings.onboarding2Desc:
        'Kamera AI mengenali gerakan isyarat secara langsung dan suara percakapan diterjemahkan menjadi teks dua arah.',
    AppStrings.onboarding3Title: 'Pilih Peran & Mulai Terhubung',
    AppStrings.onboarding3Desc:
        'Personalisasi pengalaman sebagai Teman Tuli atau Teman Dengar untuk komunikasi kafe yang ramah dan inklusif.',
    AppStrings.onboardingChipCamera: 'Kamera AI Real-time',
    AppStrings.onboardingChipSign: 'BISINDO & SIBI',
    AppStrings.onboardingSlide2BiDirectional: 'Penerjemahan Dua Arah',
    AppStrings.onboardingSlide2VoiceBarista: 'Suara Barista',
    AppStrings.onboardingSlide2VoiceGreeting:
        '"Halo! Mau pesan kopi apa hari ini?"',
    AppStrings.onboardingSlide2CashierVoice: 'Suara Kasir',
    AppStrings.onboardingSlide2RealtimeDetection: 'Deteksi Isyarat Real-time',
    AppStrings.onboardingSlide2VoiceSample: '"1x Oat Cappuccino, hangat"',
    AppStrings.onboardingSlide2AiCamera: 'Kamera Deteksi AI',
    AppStrings.onboardingSlide2Accurate: '98% Akurat',
    AppStrings.onboardingSlide2VoiceTranslation: 'Terjemahan Suara',
    AppStrings.onboardingSlide3OrderTable: 'Meja 04',
    AppStrings.onboardingSlide3OrderReady: 'Siap Diracik',
    AppStrings.onboardingSlide3Table04: 'Meja 04',
    AppStrings.onboardingSlide3CustomCoffee: 'Kustomisasi Racikan Kafe',
    AppStrings.onboardingSlide3CustomCoffeeDesc: 'Pilihan Susu, Suhu, & Manis',
    AppStrings.onboardingSlide3CashierShortcut: 'Pintasan Kasir Ramah',
    AppStrings.onboardingSlide3CashierShortcutDesc: 'Alat Transaksi Inklusif',
    AppStrings.onboardingCenterPill: 'Komunikasi Inklusif Kafe',
    AppStrings.onboardingMockupOrder: 'Pesan Kopi Susu Aren',
    AppStrings.onboardingMockupAi: 'Kamera AI • BISINDO 98%',
    AppStrings.onboardingMockupSpeech: 'Total Rp 32.000',
    AppStrings.onboardingMockupTts: 'Suara Lisan Kasir (id-ID)',
    AppStrings.onboardingMockupFlip: 'Layar Balik Hadap Lawan 180°',
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
    AppStrings.homeSignToSpeechBadge: '#KAMERA AI • REALTIME',
    AppStrings.homeSpeechToSignBadge: '#MIKROFON • SUARA LISAN',
    AppStrings.homeSignToSpeechDesc:
        'Terjemahan gerakan isyarat ke suara lisan instan.',
    AppStrings.homeSpeechToSignDesc:
        'Ubah suara lisan jadi peragaan video isyarat akurat.',
    AppStrings.homeActionStart: 'Mulai',
    AppStrings.homeWaveSearchHint: 'Cari isyarat, menu kopi, atau riwayat...',
    AppStrings.homeSelectSignLanguageDialog: 'Pilih Bahasa Isyarat',
    AppStrings.homeSelectSignLanguageDesc:
        'Pilih model kecerdasan buatan untuk penerjemahan kamera & suara lisan',
    AppStrings.homeSignBisindoTitle: 'BISINDO',
    AppStrings.homeSignBisindoDesc:
        'Bahasa Isyarat Indonesia (Alami & Berbasis Budaya Komunitas Tuli)',
    AppStrings.homeSignSibiTitle: 'SIBI',
    AppStrings.homeSignSibiDesc:
        'Sistem Isyarat Bahasa Indonesia (Struktur Tata Bahasa Baku 1 Tangan)',
    AppStrings.homeQuickSearchTitle: 'Pencarian Cepat',
    AppStrings.homeQuickSearchEmpty:
        'Tidak ada hasil yang cocok dengan kata kunci',
    AppStrings.homeQuickSearchSignCategory: 'Pustaka Isyarat',
    AppStrings.homeQuickSearchMenuCategory: 'Katalog Menu Kafe',
    AppStrings.homeQuickSearchHistoryCategory: 'Riwayat Percakapan',

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
    AppStrings.libraryNoVideosToDownload: 'Tidak Ada Video',
    AppStrings.libraryNoVideosToDownloadDesc:
        'Tidak ada video pada filter ini untuk diunduh.',
    AppStrings.libraryDownloadComplete: 'Unduhan Selesai',
    AppStrings.libraryDownloadCompleteDesc:
        '@count video berhasil tersimpan di penyimpanan offline.',
    AppStrings.pkgDownloadSuccess: 'Unduhan Berhasil',
    AppStrings.pkgDownloadSuccessDesc:
        'Paket @category telah siap digunakan offline.',
    AppStrings.pkgDownloadCancelled: 'Unduhan Dibatalkan',
    AppStrings.pkgDownloadCancelledDesc:
        'Pengunduhan paket @category telah dibatalkan.',
    AppStrings.pkgDownloadFailed: 'Unduhan Terkendala',
    AppStrings.pkgDownloadFailedDesc: 'Beberapa video paket gagal diunduh. Silakan coba kembali saat internet stabil.',
    AppStrings.pkgCleanSuccess: 'Pembersihan Selesai',
    AppStrings.pkgCleanSuccessDesc:
        '@count video unduhan telah dihapus dari memori perangkat.',

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
    AppStrings.settingsSectionGeneral: 'Umum & Tampilan',
    AppStrings.settingsSectionAudioVideo: 'Audio & Peragaan Isyarat',
    AppStrings.settingsSectionStorageConnection: 'Penyimpanan & Koneksi Data',
    AppStrings.settingsSectionSupportAbout: 'Bantuan & Tentang Aplikasi',
    AppStrings.settingsProfileEditRole: 'Ubah Peran & Aksesibilitas',
    AppStrings.settingsProfileSubtitle: 'Mode Komunikasi Kafe Inklusif',
    AppStrings.settingsAboutVersion: 'Versi Aplikasi',
    AppStrings.settingsAboutPrivacy: 'Privasi & Keamanan',
    AppStrings.settingsAboutPrivacyDesc:
        'Pemrosesan koordinat AI berjalan 100% lokal di perangkat.',
    AppStrings.settingsGuideTitle: 'Panduan Penggunaan',
    AppStrings.settingsGuideDesc:
        'Buka ulang tutorial onboarding & gestur isyarat',
    AppStrings.settingsSupabaseConnection: 'Koneksi Cloud Supabase',
    AppStrings.settingsSupabaseDesc:
        'Sinkronisasi riwayat & katalog video kafe',
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
    AppStrings.settingsThemeModeDesc:
        'Pilih tampilan terang atau gelap (Instagram AMOLED)',
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
    AppStrings.cashierFlipScreenDesc:
        'Putar tampilan agar mudah dibaca oleh orang di seberang meja kasir',
    AppStrings.cashierCustomerViewBadge: 'Tampilan Kasir & Pelanggan',
    AppStrings.cashierOpenAssistant: 'Buka Alat Kasir & Belanja',

    // Onboarding 3 Badges
    AppStrings.onboardingBadgePresets: 'Papan Nominal Cepat',
    AppStrings.onboardingBadgeFlipScreen: 'Layar Balik Hadap Lawan',

    // Sign to Speech Result
    AppStrings.signResultTitle: 'Hasil Sign to Speech',
    AppStrings.signResultOriginalSign: 'Isyarat Asli',
    AppStrings.signResultPlayVoice: 'Putar Suara',
    AppStrings.signResultCopyText: 'Salin Teks',
    AppStrings.signResultCopied: 'Disalin',
    AppStrings.signResultCopiedDesc:
        'Teks terjemahan berhasil disalin ke papan klip',
    AppStrings.signResultSaveHistory: 'Simpan ke Riwayat',
    AppStrings.signResultSaved: 'Tersimpan',
    AppStrings.signResultSavedDesc: 'Terjemahan berhasil disimpan ke Riwayat',
    AppStrings.signResultBackToCamera: 'Kembali ke Kamera',

    // Cafe POS & 8 Killer Features
    AppStrings.cafeAutoOrderTitle: 'Draf Pesanan Otomatis',
    AppStrings.cafeAutoOrderSubtitle:
        'Terdeteksi dari transkrip kamera / suara',
    AppStrings.cafeConfirmToTicket: 'Konfirmasi Masuk Nota',
    AppStrings.cafeParsedSlotDetected: 'Slot Terisi Otomatis',
    AppStrings.cafeModifierExtraShot: 'Extra Shot Espresso',

    AppStrings.cafeCupNameTitle: 'Eja Nama Cup (1500ms)',
    AppStrings.cafeCupNameSubtitle: 'Gunakan alfabet jari BISINDO',
    AppStrings.cafeCupNameActive: 'Mode Eja Nama Aktif',
    AppStrings.cafeCupNameFinish: 'Selesai Eja / Spasi',
    AppStrings.cafeCupNameFor: 'Atas nama:',

    AppStrings.cafeAiSommelierTitle: 'AI Barista Sommelier',
    AppStrings.cafeAiSommelierSubtitle:
        'Rekomendasi Berdasarkan Kosakata Dasar',
    AppStrings.cafeAiChooseCustomize: 'Pilih & Kustomisasi',
    AppStrings.cafeAiMatchedReason: 'Alasan Rekomendasi',

    AppStrings.cafeQueuePagerTitle: 'Panggilan Antrean 2-Arah',
    AppStrings.cafeCallHearing: 'Panggil Pelanggan Dengar (FIFO TTS)',
    AppStrings.cafeCallDeaf: 'Panggil Pelanggan Tuli (Visual + Getar)',
    AppStrings.cafeOrderReady: 'Pesanan Siap Diambil!',
    AppStrings.cafeOrderReadyDesc: 'Silakan ambil di meja bar racik',

    AppStrings.cafeQuickDeckTitle: '1-Tap Cashier Quick Deck',
    AppStrings.cafeQuickDeckSubtitle: 'Suara TTS + Video Isyarat Sekaligus',
    AppStrings.quickDeck1:
        'Minum di sini (Dine-in) atau bawa pulang (Takeaway)?',
    AppStrings.quickDeck2: 'Mau ukuran Small, Medium, atau Large?',
    AppStrings.quickDeck3: 'Takaran es dan gulanya normal atau dikurangi?',
    AppStrings.quickDeck4: 'Untuk atas nama siapa di cup-nya?',
    AppStrings.quickDeck5: 'Silakan scan QRIS di layar, totalnya sudah sesuai.',
    AppStrings.quickDeck6:
        'Terima kasih, mohon tunggu sebentar di area pickup.',

    AppStrings.cafeDietaryAlertTitle: 'Peringatan Keselamatan Racikan',
    AppStrings.alertLactose: 'Intoleransi Laktosa (Wajib Oat/Soy)',
    AppStrings.alertDiabetes: 'Pantangan Gula / Diabetes (0%)',
    AppStrings.alertNut: 'Alergi Kacang Ekstrem (Tanpa Hazelnut/Almond)',
    AppStrings.alertDairy: 'Alergi Susu Sapi (Wajib Plant Milk)',
    AppStrings.alertMaag: 'Sensitif Maag / Asam Lambung (Pilih Low-Acid)',

    AppStrings.cafeTicketTitle: 'Tiket Pesanan Kafe',
    AppStrings.cafeSubtotal: 'Subtotal',
    AppStrings.cafeTax: 'Pajak PB1 (10%)',
    AppStrings.cafeGrandTotal: 'Total Pembayaran',
    AppStrings.cafePaymentQris: 'QRIS Visual',
    AppStrings.cafePaymentCash: 'Tunai (Cash)',
    AppStrings.cafeAmountReceived: 'Uang Diterima',
    AppStrings.cafeChange: 'Kembalian',
    AppStrings.cafeTranslateBill: 'Terjemahkan ke Isyarat & Suara',

    AppStrings.cafeWaitingChallengeTitle:
        'Belajar 1 Isyarat Kopi Sambil Menunggu',
    AppStrings.cafeWaitingChallengeDesc:
        'Praktikkan di kamera & dapatkan apresiasi barista!',
    AppStrings.cafeTryCamera: 'Coba Praktikkan di Kamera',
    AppStrings.cafeChallengeSuccess: 'Luar biasa! Gestur kamu terkonfirmasi!',
    AppStrings.cafeHoldGuide: 'Tahan gestur di depan kamera...',

    AppStrings.cafeCoffeeDetailTitle: 'Detail Racikan Kopi',
    AppStrings.cafeSendToCashier: 'Kirim ke Meja Kasir',
    AppStrings.cafeDualViewCustomer: 'Sisi Pembeli',
    AppStrings.cafeDualViewCashier: 'Sisi Kasir',
    AppStrings.cafeQueueNumber: 'Nomor Antrean',
    AppStrings.cafeCompositionOat: 'Oat Milk Creamy',
    AppStrings.cafeCompositionFoam: 'Microfoam Halus',
    AppStrings.cafeCompositionEspresso: 'Espresso Arabika Gayo',

    AppStrings.cafeLiveOrderCameraTitle: 'Live Kamera & Suara Pesanan',
    AppStrings.cafeLiveOrderCameraHint:
        'Arahkan gestur isyarat atau suara pesanan ke kasir',
    AppStrings.cafeSpellingCameraTitle: 'Kamera Eja Nama Cup',
    AppStrings.cafeSpellingCameraHint: 'Peragakan huruf alfabet satu per satu',
    AppStrings.cafeChallengeHintBtn: 'Lihat Petunjuk Isyarat',
    AppStrings.cafeChallengeCloseCamera: 'Tutup Kamera',
    AppStrings.cafeSwitchCamera: 'Ganti Kamera',
    AppStrings.cafeDetectedLetter: 'Huruf Terdeteksi',
    AppStrings.cafeHoldConfirming: 'Menahan gestur...',
    AppStrings.cafeCameraActive: 'Kamera Aktif',
    AppStrings.cafeOpenLiveCamera: 'Buka Kamera Isyarat',
    AppStrings.cafeCloseLiveCamera: 'Tutup Kamera Isyarat',
    AppStrings.cafeDeleteOrderTitle: 'Hapus Pesanan?',
    AppStrings.cafeDeleteOrderConfirm:
        'Apakah Anda yakin ingin menghapus @name dari tiket pesanan?',
    AppStrings.cafeDeleteItem: 'Hapus',
    AppStrings.cafeForCustomerName: 'Atas nama: @name',
    AppStrings.cafeSignVideoReady: 'VIDEO ISYARAT DIPUTAR: "PESANAN SIAP"',
    AppStrings.cafeCloseNotification: 'Tutup Notifikasi',
    AppStrings.cafeTrophyTitle: 'Bintang Isyarat Kafe!',
    AppStrings.cafeTrophyDesc: 'Luar biasa! Gestur "@sign" berhasil Anda peragakan dengan sempurna. Barista sangat mengapresiasi upaya Anda!',
    AppStrings.cafeTrophyAction: 'Mantap!',

    AppStrings.cafeEmptyTicket: 'Belum ada item pesanan dalam nota.',
    AppStrings.cafeCustomerNotesPrefix: 'Pilihan Pelanggan: @notes',
    AppStrings.cafeSubstituteOatMilk: 'Ganti ke Susu Oat (Bebas Laktosa)',
    AppStrings.cafeExactCash: 'Uang Pas',
    AppStrings.cafeCompleteCashPayment: 'Selesaikan Pembayaran Tunai',
    AppStrings.cafeQrisNationalStandard: 'STANDAR PEMBAYARAN NASIONAL',
    AppStrings.cafeQrisVerifying: 'Memproses Verifikasi...',
    AppStrings.cafeQrisSimulatePay: 'Simulasi Bayar QRIS Sekarang',
    AppStrings.cafePaymentSuccessServing: 'Pembayaran Sukses • Siap Disajikan',
    AppStrings.cafeResetTicketTooltip: 'Pesanan Baru / Reset Nota',
    AppStrings.cafeTranscriptInputHint: 'Ketik atau ucapkan pesanan...',
    AppStrings.cafeProcessOrder: 'Proses',
    AppStrings.cafeListeningVoiceNow:
        'SEDANG MENDENGARKAN SUARA (BICARA SEKARANG)...',
    AppStrings.cafeSimulatorTranscriptTitle:
        'SIMULATOR TRANSKRIP KAMERA / MIKROFON',
    AppStrings.cafeQuickExamples: 'Contoh Cepat',
    AppStrings.cafeDetectedPrefix: 'Terdeteksi: @text',
    AppStrings.cafeQuickOrderAction: 'Pesan Ini',
    AppStrings.cafeCameraListeningGestures:
        'KAMERA ISYARAT AKTIF (ARAHKAN GESTUR PESANAN)...',
    AppStrings.cafeOpenMenuCatalog: 'Buka Katalog Menu',

    AppStrings.cafeSignGuideTitle: 'Panduan Isyarat: "@word"',
    AppStrings.cafeReadyToPractice: 'Saya Siap Praktikkan di Kamera',
    AppStrings.cafeChangeSignTooltip: 'Ganti Isyarat Lain',
    AppStrings.cafeChallengeTitle: 'Tantangan: "@word"',
    AppStrings.cafeMatchPercentage: '@percent% Cocok',
    AppStrings.cafeTodaySignTitle: 'ISYARAT HARI INI:',
    AppStrings.cafeAimGestureHint: 'Arahkan gestur tangan ke kamera kafe',
    AppStrings.cafeTryAgain: 'Coba Lagi',
    AppStrings.cafeHoldForLetter: 'Tahan untuk "@letter"',
    AppStrings.cafeTouchToSpell: 'Sentuh huruf untuk mengeja...',
    AppStrings.cafeDeleteLastLetter: 'Hapus Huruf Terakhir',
    AppStrings.cafeOfficialReceipt: 'STRUK RESMI KAFE',
    AppStrings.cafeSelect: 'Pilih',
    AppStrings.cashierGreetingPrompt: 'Halo! Mau pesan apa hari ini?',
    AppStrings.cashierScreenNormal: 'Normal (0°)',
    AppStrings.cashierSpeakThisText: 'Ucapkan Teks Ini',
    AppStrings.cafeSpellingHintUnlimited: 'Peragakan isyarat huruf atau sentuh abjad. Tekan Simpan Nama jika sudah.',
    AppStrings.cafeCashierBaristaAiTitle: 'Meja Kasir & Barista AI',
    AppStrings.cafeQueueNumberPrefix: 'Nomor Antrean: @queue',
    AppStrings.cafeClearTicketTooltip: 'Bersihkan Nota & Transkrip',
    AppStrings.cafeBackTooltip: 'Kembali',

    // Queue Management
    AppStrings.cafeOrderQueueTitle: 'Antrean Pesanan',
    AppStrings.cafeOrderQueueSubtitle:
        'Daftar pesanan dalam proses & menunggu pengambilan',
    AppStrings.cafeOrderQueueBadge: '@count Antrean',
    AppStrings.cafeOrderQueueEmpty: 'Belum Ada Pesanan dalam Antrean',
    AppStrings.cafeOrderQueueEmptyDesc: 'Pesanan yang selesai dibayar otomatis masuk ke sini untuk diproses barista.',
    AppStrings.cafeStartNextOrder: 'Catat Pesanan Selanjutnya',
    AppStrings.cafePaymentSuccessQueued:
        'Pembayaran Lunas! Pesanan @queue Masuk Antrean',
    AppStrings.cafeViewQueue: 'Lihat Antrean (@count)',
    AppStrings.cafeFilterAll: 'Semua',
    AppStrings.cafeFilterPreparing: 'Sedang Dibuat',
    AppStrings.cafeFilterReady: 'Siap Diambil',
    AppStrings.cafeFilterCompleted: 'Selesai',
    AppStrings.cafeMarkPreparing: 'Mulai Buat',
    AppStrings.cafeMarkReady: 'Tandai Siap',
    AppStrings.cafeMarkCompleted: 'Selesai / Serahkan',
    AppStrings.cafeCallCustomerVoice: 'Panggil Suara (TTS)',
    AppStrings.cafeCallCustomerDeaf: 'Panggil Teman Tuli',
    AppStrings.cafeOrderElapsedMinutes: '@minutes mnt lalu',
    AppStrings.cafeOrderElapsedSeconds: 'Baru saja',

    // Sign Sentence Accumulator
    AppStrings.cafeSignSentenceBuilderTitle: 'Rangkaian Isyarat Terdeteksi',
    AppStrings.cafeDeleteLastWord: 'Hapus Kata',
    AppStrings.cafeClearSentence: 'Hapus Kalimat',
    AppStrings.cafeSentenceEmpty:
        'Peragakan isyarat untuk menyusun kalimat pesanan...',
    AppStrings.cafeWordDetected: 'Terdeteksi: @word',

    // Modern Menu Catalog & Input Bar
    AppStrings.cafeCatalogTitle: 'Katalog Menu Kafe Modern',
    AppStrings.cafeCatalogSubtitle:
        'Pilih minuman favorit atau sesuaikan racikan barista',
    AppStrings.cafeCatalogSearchHint: 'Cari menu kopi, aren, matcha, oat...',
    AppStrings.cafeCategoryAll: 'Semua Menu',
    AppStrings.cafeCategoryMilkCoffee: 'Kopi Susu',
    AppStrings.cafeCategoryBlackCoffee: 'Kopi Hitam',
    AppStrings.cafeCategoryGentleStomach: 'Ramah Lambung',
    AppStrings.cafeCategoryNonCoffee: 'Non-Kopi',
    AppStrings.cafeCustomize: 'Kustomisasi',
    AppStrings.cafeQuickAdd: '+ Tambah',
    AppStrings.cafeMenuNotFound: 'Menu Tidak Ditemukan',
    AppStrings.cafeMenuNotFoundDesc:
        'Coba kata kunci lain atau pilih kategori di atas.',
    AppStrings.cafeResetSearch: 'Reset Pencarian',
    AppStrings.cafeItemsAvailable: '@count menu siap dipesan',
    AppStrings.cafeModeSignCamera: 'Kamera Isyarat',
    AppStrings.cafeModeVoiceStt: 'Suara (Mic)',
    AppStrings.cafeModeMenuCatalog: 'Katalog Menu',
    AppStrings.cafeQuickPicksTitle: 'Pilihan Cepat & Alergi',
    AppStrings.cafeClearInputTooltip: 'Hapus Teks',

    // Customer Voice Order & Cashier Sign Video
    AppStrings.cafeCustomerVoiceOrderTitle: 'Pesan Kopi Lewat Suara',
    AppStrings.cafeCustomerVoiceOrderSubtitle:
        'Bicara untuk memesan, teks dapat diedit sebelum dikirim',
    AppStrings.cafeCustomerVoiceMicTap: 'Ketuk untuk Bicara',
    AppStrings.cafeCustomerVoiceListening:
        'Mendengarkan... Silakan bicara pesanan Anda',
    AppStrings.cafeCustomerVoiceHint:
        'Hasil ucapan suara Anda akan muncul di sini dan dapat diedit langsung',
    AppStrings.cafeCustomerVoiceEditHint:
        'Edit teks pesanan jika ada yang kurang tepat...',
    AppStrings.cafeCustomerVoiceSend: 'Kirim Pesanan ke Kasir',
    AppStrings.cafeCustomerVoiceSentSnackbar:
        'Pesanan dikirim! Terjemahan isyarat aktif di layar kasir.',
    AppStrings.cafeCustomerVoiceSignBadge:
        'Terjemahan Isyarat Real-Time di Kasir',
    AppStrings.cafeCustomerQuickTagsTitle: 'Pilihan Cepat Tambahan',
    AppStrings.cafeCashierSignVideoTitle: 'Video Bahasa Isyarat Pesanan',
    AppStrings.cafeCashierSignVideoSubtitle:
        'Terjemahan isyarat realtime dari suara pembeli',
    AppStrings.cafeCashierSignStandby: 'Siap Menampilkan Isyarat',
    AppStrings.cafeCashierSignStandbyDesc: 'Saat pembeli memesan lewat suara, video bahasa isyarat otomatis tampil di sini.',
    AppStrings.cafeCashierSignOfflineBadge: 'Offline (Aset)',
    AppStrings.cafeCashierSignCachedBadge: 'Offline (Tersimpan)',
    AppStrings.cafeCashierSignOnlineBadge: 'Online CDN',
    AppStrings.cafeCashierSignDownload: 'Unduh Offline',
    AppStrings.cafeCashierSignDownloading: 'Mengunduh video...',
    AppStrings.cafeCashierSignWordChips: 'Urutan Kosakata Isyarat',

    // Customer Mode Switch & Camera Sign Detection
    AppStrings.cafeCustomerModeMic: 'Suara (Mic)',
    AppStrings.cafeCustomerModeCamera: 'Bahasa Isyarat',
    AppStrings.cafeCustomerCameraActiveTitle: 'Deteksi Isyarat Pesanan',
    AppStrings.cafeCustomerCameraSubtitle:
        'Arahkan tangan ke kamera untuk memesan lewat isyarat',
    AppStrings.cafeCustomerCameraReady: 'Siap — lakukan isyarat pesanan',
    AppStrings.cafeCustomerDeleteLastWord: 'Hapus Kata Terakhir',
    AppStrings.cafeCustomerClearSentence: 'Reset Isyarat',
    AppStrings.cafeCustomerQuickSignChips: 'Simulasi Isyarat Cepat:',
    AppStrings.cafeSignModelChanged: 'Model bahasa isyarat diubah ke @model',

    // Sign Video Player Controls & Indicators
    AppStrings.signVideoPlay: 'Putar',
    AppStrings.signVideoPause: 'Jeda',
    AppStrings.signVideoReplay: 'Putar Ulang',
    AppStrings.signVideoLoop: 'Ulangi Otomatis',
    AppStrings.signVideoOfflineBadge: 'Video Offline',
    AppStrings.signVideoCachedBadge: 'Tersimpan di Cache',
    AppStrings.signVideoOnlineBadge: 'Online CDN (Dapat Diunduh)',
    AppStrings.signVideoDownloadAction: 'Unduh Video',
    AppStrings.signVideoDownloading: 'Mengunduh video...',
    AppStrings.signVideoDownloadingTitle: 'Mengunduh Video Isyarat',
    AppStrings.signVideoDownloadingDesc:
        'Menyimpan video ke memori cache untuk akses cepat tanpa internet',
    AppStrings.signVideoDownloadComplete: 'Unduhan Selesai',
    AppStrings.signVideoStatusPlaying: 'Memutar',
    AppStrings.signVideoStatusPaused: 'Dijeda',

    // Cafe Cashier Control Sheet
    AppStrings.cafeMenuMoreTooltip: 'Menu & Kontrol Kasir',
    AppStrings.cafeControlSheetTitle: 'Menu & Kontrol Kasir',
    AppStrings.cafeControlSheetSubtitle:
        'Pengaturan model isyarat, antrean, dan sesi meja',
    AppStrings.cafeControlSignModelTitle: 'Model Bahasa Isyarat',
    AppStrings.cafeControlSignModelDesc:
        'Standar isyarat aktif untuk deteksi kamera dan video',
    AppStrings.cafeControlBisindoDesc:
        'Bahasa Isyarat Indonesia (2 Tangan / Sehari-hari)',
    AppStrings.cafeControlSibiDesc:
        'Sistem Isyarat Bahasa Indonesia (1 Tangan / Formal)',
    AppStrings.cafeControlQueueTitle: 'Antrean Pesanan Kafe',
    AppStrings.cafeControlQueueDesc: '@count pesanan aktif dalam antrean',
    AppStrings.cafeControlQueueOpen: 'Buka Antrean',
    AppStrings.cafeControlStaffTitle: 'Keamanan & PIN Staf',
    AppStrings.cafeControlStaffLoggedIn: 'Staf Kasir Terverifikasi',
    AppStrings.cafeControlStaffLocked: 'Mode Terkunci (Perlu PIN Staf)',
    AppStrings.cafeControlStaffLogin: 'Masuk PIN',
    AppStrings.cafeControlStaffLogout: 'Keluar Staf',
    AppStrings.cafeControlResetTitle: 'Reset Transaksi & Meja Baru',
    AppStrings.cafeControlResetDesc:
        'Kosongkan nota dan kembali ke status standby',
    AppStrings.cafeControlResetConfirm: 'Yakin ingin mereset meja ini? Pesanan yang belum tersimpan akan dikosongkan.',
    AppStrings.cafeControlResetCancel: 'Batal',

    // Customer Side Menu Catalog Banner
    AppStrings.cafeCustomerMenuBannerTitle: 'Katalog Menu Lengkap',
    AppStrings.cafeCustomerMenuBannerSubtitle:
        'Jelajahi varian kopi, susu nabati ramah lambung, & camilan',
    AppStrings.cafeCustomerMenuBannerButton: 'Buka Menu',

    // Coffee Detail Screen Order Sent Dialog
    AppStrings.cafeOrderSentSuccessTitle: 'Pesanan Berhasil Dikirim!',
    AppStrings.cafeOrderSentSuccessDesc: 'Racikan kopi Anda telah berhasil ditambahkan ke antrean kasir & barista.',
    AppStrings.cafeOrderSentSignSyncNotice:
        'Tersinkronisasi otomatis dengan video isyarat kasir',
    AppStrings.cafeOrderSentConfirmButton: 'OK, Selesai',

    // Cashier Order Deck (3-Tab Deck: Bahasa Isyarat, 1-Tap, Mic)
    AppStrings.cafeCashierDeckTitle: 'Komunikasi & Pesanan Kasir',
    AppStrings.cafeCashierDeckSubtitle:
        'Deteksi isyarat pembeli, aksi 1-tap kasir, dan input suara',
    AppStrings.cafeCashierTabSign: 'Bahasa Isyarat',
    AppStrings.cafeCashierTabQuick: '1-Tap',
    AppStrings.cafeCashierTabMic: 'Suara (Mic)',
    AppStrings.cafeCashierCameraActiveTitle: 'Deteksi Isyarat Kasir',
    AppStrings.cafeCashierCameraSubtitle:
        'Kamera aktif membaca gestur tangan pembeli di depan kasir',
    AppStrings.cafeCashierMicTap: 'Ketuk untuk Bicara (Kasir)',
    AppStrings.cafeCashierMicListening: 'Mendengarkan ucapan kasir...',
    AppStrings.cafeCashierMicHint:
        'Ucapan suara Anda akan dikonversi ke teks dan video bahasa isyarat',
    AppStrings.cafeCashierSubmitOrder: 'Proses Pesanan ke Nota',
    AppStrings.cafeCashierSubmitEmptyWarning: 'Silakan gunakan isyarat, 1-tap, atau bicara untuk memesan terlebih dahulu.',
    AppStrings.cafeCashierSubmitSuccess:
        'Pesanan berhasil dikonfirmasi ke nota transaksi!',

    // Flip & Device Mode
    AppStrings.cafeFlipScreen: 'Putar Layar 180°',
    AppStrings.cafeFlipTooltip: 'Putar tampilan 180° menghadap pembeli',
    AppStrings.cafeDeviceModeTitle: 'Mode Perangkat Kasir',
    AppStrings.cafeDeviceModeDesc: 'Pilih konfigurasi tablet kasir & pelanggan',
    AppStrings.cafeMode1Tablet: '1 Tablet (Putar 180°)',
    AppStrings.cafeMode1TabletDesc:
        'Satu tablet bergantian atau diputar 180° menghadap pembeli',
    AppStrings.cafeMode2Tablet: '2 Tablet (Sinkron Ruang)',
    AppStrings.cafeMode2TabletDesc:
        'Dua tablet saling sinkron real-time via kode ruangan',
    AppStrings.cafeRoomCodeLabel: 'Kode Ruangan Meja Kasir',
    AppStrings.cafeRoomCodeHint: 'Contoh: KAFE-01',
    AppStrings.cafeCreateRoom: 'Buat Ruang Baru',
    AppStrings.cafeJoinRoom: 'Hubungkan Ruang',
    AppStrings.cafeRoomCreated: 'Ruangan berhasil dibuat & disinkronkan',
    AppStrings.cafeRoomJoined: 'Berhasil terhubung ke ruangan kasir',
    AppStrings.cafeRoomCodeCopied: 'Kode ruangan disalin ke clipboard',
    AppStrings.cafeFlipActive: 'Layar diputar 180° menghadap pembeli',
    AppStrings.cafeFlipInactive: 'Layar kembali ke posisi normal kasir',
    AppStrings.cafeCashierCameraClosedTitle: 'Kamera Deteksi Isyarat Siap',
    AppStrings.cafeCashierCameraClosedDesc: 'Kamera tertutup untuk menghemat daya & menjaga privasi. Buka kamera saat siap memesan dengan bahasa isyarat.',
    AppStrings.cafeCashierCameraClosedBadge: 'Kamera Tertutup',

    // Dual Tablet PIN Role Separation
    AppStrings.cafeDualStaffHostTitle: 'Tablet Kasir (Host Ruangan)',
    AppStrings.cafeDualStaffHostDesc: 'Tablet ini bertindak sebagai Meja Kasir. Bagikan kode ruangan ini ke Tablet Pelanggan.',
    AppStrings.cafeDualCustomerTitle: 'Tablet Pelanggan (Layar Hadap)',
    AppStrings.cafeDualCustomerDesc:
        'Masukkan kode ruangan dari meja kasir untuk menghubungkan tablet ini.',
    AppStrings.cafeDualCustomerConnected: 'Terhubung ke Meja Kasir',
    AppStrings.cafeDualStaffLoginPrompt: 'Ini tablet kasir? Masuk PIN Staf',
    AppStrings.cafeDualHostBadge: 'HOST KASIR',
    AppStrings.cafeDualCustomerBadge: 'LAYAR PELANGGAN',

    // Stage Advance Bottom Action Bar
    AppStrings.cafeStageAdvanceNaming: 'Lanjut: Nama & Bayar',
    AppStrings.cafeStageAdvanceNamingWithCount:
        'Lanjut: Nama & Bayar (@count item)',
    AppStrings.cafeStageAdvancePickup: 'Lanjut: Ambil Kopi',
    AppStrings.cafeStageWaitingPayment: 'Menunggu Pembayaran',
    AppStrings.cafeStageOrderCompleted: 'Selesai & Order Baru',

    // Menu Photo CRUD (Supabase Storage)
    AppStrings.cafeMenuPhotoChange: 'Ubah Foto Menu',
    AppStrings.cafeMenuPhotoCamera: 'Ambil dari Kamera',
    AppStrings.cafeMenuPhotoGallery: 'Pilih dari Galeri',
    AppStrings.cafeMenuPhotoUploading: 'Mengunggah foto menu...',
    AppStrings.cafeMenuPhotoUploadSuccess: 'Foto menu berhasil diperbarui!',
    AppStrings.cafeMenuPhotoUploadFailed: 'Gagal mengunggah foto menu',
  };

  static Map<String, String> get _enUS => {
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
    AppStrings.previous: 'Previous',
    AppStrings.paginationShowing: 'Showing @start-@end of @total signs',
    AppStrings.paginationPageOf: 'Page @page of @total',
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
    AppStrings.onboarding1Title: 'Easier & Inclusive Communication',
    AppStrings.onboarding1Desc:
        'Instantly bridge interaction between Deaf and Hearing friends with artificial intelligence in cafes.',
    AppStrings.onboarding2Title: 'Real-Time Sign AI & Spoken Voice',
    AppStrings.onboarding2Desc:
        'AI camera recognizes sign language in real-time, and spoken words are transcribed for two-way clarity.',
    AppStrings.onboarding3Title: 'Choose Your Role & Stay Connected',
    AppStrings.onboarding3Desc:
        'Personalize your experience as Deaf or Hearing for friendly, seamless, and inclusive cafe interactions.',
    AppStrings.onboardingChipCamera: 'Real-time AI Camera',
    AppStrings.onboardingChipSign: 'BISINDO & SIBI',
    AppStrings.onboardingSlide2BiDirectional: 'Two-Way Translation',
    AppStrings.onboardingSlide2VoiceBarista: 'Barista Voice',
    AppStrings.onboardingSlide2VoiceGreeting:
        '"Hello! What can I get for you today?"',
    AppStrings.onboardingSlide2CashierVoice: 'Cashier Voice',
    AppStrings.onboardingSlide2RealtimeDetection: 'Real-time Gesture Detection',
    AppStrings.onboardingSlide2VoiceSample: '"1x Hot Oat Cappuccino"',
    AppStrings.onboardingSlide2AiCamera: 'AI Detection Camera',
    AppStrings.onboardingSlide2Accurate: '98% Accurate',
    AppStrings.onboardingSlide2VoiceTranslation: 'Voice Translation',
    AppStrings.onboardingSlide3OrderTable: 'Table 04',
    AppStrings.onboardingSlide3OrderReady: 'Ready to Brew',
    AppStrings.onboardingSlide3Table04: 'Table 04',
    AppStrings.onboardingSlide3CustomCoffee: 'Custom Cafe Recipe',
    AppStrings.onboardingSlide3CustomCoffeeDesc: 'Milk, Temperature, & Sweetness',
    AppStrings.onboardingSlide3CashierShortcut: 'Friendly Cashier Shortcut',
    AppStrings.onboardingSlide3CashierShortcutDesc: 'Inclusive Transaction Tool',
    AppStrings.onboardingCenterPill: 'Inclusive Communication',
    AppStrings.onboardingMockupOrder: 'Order Aren Latte',
    AppStrings.onboardingMockupAi: 'AI Camera • BISINDO 98%',
    AppStrings.onboardingMockupSpeech: 'Total \$2.50',
    AppStrings.onboardingMockupTts: 'Cashier Spoken Voice',
    AppStrings.onboardingMockupFlip: '180° Facing Customer Display',
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
    AppStrings.homeSignToSpeechBadge: '#AI CAMERA • REALTIME',
    AppStrings.homeSpeechToSignBadge: '#MIC • SPOKEN AUDIO',
    AppStrings.homeSignToSpeechDesc:
        'Instant sign gestures to spoken voice translation.',
    AppStrings.homeSpeechToSignDesc:
        'Convert spoken voice to accurate sign language video.',
    AppStrings.homeActionStart: 'Start',
    AppStrings.homeWaveSearchHint: 'Search signs, cafe menu, or history...',
    AppStrings.homeSelectSignLanguageDialog: 'Select Sign Language',
    AppStrings.homeSelectSignLanguageDesc:
        'Choose AI model for camera gesture and spoken voice translation',
    AppStrings.homeSignBisindoTitle: 'BISINDO',
    AppStrings.homeSignBisindoDesc:
        'Indonesian Sign Language (Natural & Deaf Community Heritage)',
    AppStrings.homeSignSibiTitle: 'SIBI',
    AppStrings.homeSignSibiDesc:
        'Indonesian Sign System (Standardized Grammatical Structure)',
    AppStrings.homeQuickSearchTitle: 'Quick Search',
    AppStrings.homeQuickSearchEmpty: 'No results found matching keyword',
    AppStrings.homeQuickSearchSignCategory: 'Sign Library',
    AppStrings.homeQuickSearchMenuCategory: 'Cafe Menu Catalog',
    AppStrings.homeQuickSearchHistoryCategory: 'Conversation History',

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
    AppStrings.libraryNoVideosToDownload: 'No Videos Found',
    AppStrings.libraryNoVideosToDownloadDesc:
        'There are no videos under this filter to download.',
    AppStrings.libraryDownloadComplete: 'Download Complete',
    AppStrings.libraryDownloadCompleteDesc:
        '@count videos successfully saved to offline storage.',
    AppStrings.pkgDownloadSuccess: 'Download Complete',
    AppStrings.pkgDownloadSuccessDesc:
        'The @category package is now ready for offline use.',
    AppStrings.pkgDownloadCancelled: 'Download Cancelled',
    AppStrings.pkgDownloadCancelledDesc:
        'The download for @category package was cancelled.',
    AppStrings.pkgDownloadFailed: 'Download Interrupted',
    AppStrings.pkgDownloadFailedDesc: 'Some package videos failed to download. Please retry on a stable connection.',
    AppStrings.pkgCleanSuccess: 'Cleanup Complete',
    AppStrings.pkgCleanSuccessDesc:
        '@count downloaded videos were cleared from device storage.',

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
    AppStrings.settingsSectionPreferences: 'Preferences & Accessibility',
    AppStrings.settingsSectionGeneral: 'General & Display',
    AppStrings.settingsSectionAudioVideo: 'Audio & Sign Playback',
    AppStrings.settingsSectionStorageConnection: 'Storage & Data Connection',
    AppStrings.settingsSectionSupportAbout: 'Support & About App',
    AppStrings.settingsProfileEditRole: 'Change Role & Accessibility',
    AppStrings.settingsProfileSubtitle: 'Inclusive Cafe Communication Mode',
    AppStrings.settingsAboutVersion: 'App Version',
    AppStrings.settingsAboutPrivacy: 'Privacy & Security',
    AppStrings.settingsAboutPrivacyDesc:
        'AI coordinate processing runs 100% locally on-device.',
    AppStrings.settingsGuideTitle: 'User Guide',
    AppStrings.settingsGuideDesc: 'Reopen onboarding tutorial & sign gestures',
    AppStrings.settingsSupabaseConnection: 'Supabase Cloud Connection',
    AppStrings.settingsSupabaseDesc: 'Sync history & cafe video catalog',
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
    AppStrings.settingsThemeModeDesc:
        'Choose Light or Dark (Instagram AMOLED) mode',
    AppStrings.themeModeSystem: 'System Default',
    AppStrings.themeModeLight: 'Light (Cafe Cream)',
    AppStrings.themeModeDark: 'Dark (Instagram)',

    // Cashier & Customer Assistant
    AppStrings.cashierAssistantTitle: 'Cashier & Shopping Assistant',
    AppStrings.cashierAssistantSubtitle:
        'Friendly Communication at the Counter',
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
    AppStrings.cashierFlipScreenDesc:
        'Rotate screen so person across the counter can read effortlessly',
    AppStrings.cashierCustomerViewBadge: 'Cashier & Customer Display',
    AppStrings.cashierOpenAssistant: 'Open Cashier Assistant',

    // Onboarding 3 Badges
    AppStrings.onboardingBadgePresets: 'Quick Price Pad',
    AppStrings.onboardingBadgeFlipScreen: '180° Facing Display',

    // Sign to Speech Result
    AppStrings.signResultTitle: 'Sign to Speech Result',
    AppStrings.signResultOriginalSign: 'Original Sign',
    AppStrings.signResultPlayVoice: 'Play Voice',
    AppStrings.signResultCopyText: 'Copy Text',
    AppStrings.signResultCopied: 'Copied',
    AppStrings.signResultCopiedDesc: 'Translation copied to clipboard',
    AppStrings.signResultSaveHistory: 'Save to History',
    AppStrings.signResultSaved: 'Saved',
    AppStrings.signResultSavedDesc: 'Translation saved to History',
    AppStrings.signResultBackToCamera: 'Back to Camera',

    // Cafe POS & 8 Killer Features
    AppStrings.cafeAutoOrderTitle: 'Auto Order Draft',
    AppStrings.cafeAutoOrderSubtitle: 'Detected from sign / voice transcript',
    AppStrings.cafeConfirmToTicket: 'Confirm to Ticket',
    AppStrings.cafeParsedSlotDetected: 'Auto Slot Populated',
    AppStrings.cafeModifierExtraShot: 'Extra Espresso Shot',

    AppStrings.cafeCupNameTitle: 'Fingerspell Cup Name (1500ms)',
    AppStrings.cafeCupNameSubtitle: 'Use BISINDO fingerspelling',
    AppStrings.cafeCupNameActive: 'Spelling Mode Active',
    AppStrings.cafeCupNameFinish: 'Finish Spelling / Space',
    AppStrings.cafeCupNameFor: 'Cup Name:',

    AppStrings.cafeAiSommelierTitle: 'AI Barista Sommelier',
    AppStrings.cafeAiSommelierSubtitle: 'Smart Recommendation via Basic Vocab',
    AppStrings.cafeAiChooseCustomize: 'Select & Customize',
    AppStrings.cafeAiMatchedReason: 'Why Barista Recommends',

    AppStrings.cafeQueuePagerTitle: 'Dual-Mode Queue Pager',
    AppStrings.cafeCallHearing: 'Call Hearing Customer (FIFO TTS)',
    AppStrings.cafeCallDeaf: 'Call Deaf Customer (Visual + Haptic)',
    AppStrings.cafeOrderReady: 'Order is Ready for Pickup!',
    AppStrings.cafeOrderReadyDesc: 'Please pickup at the barista bar counter',

    AppStrings.cafeQuickDeckTitle: '1-Tap Cashier Quick Deck',
    AppStrings.cafeQuickDeckSubtitle: 'Instant TTS Voice + Sign Video Sync',
    AppStrings.quickDeck1: 'Dine-in or Takeaway?',
    AppStrings.quickDeck2: 'Small, Medium, or Large size?',
    AppStrings.quickDeck3: 'Normal ice & sugar, or less?',
    AppStrings.quickDeck4: 'What name should I write on the cup?',
    AppStrings.quickDeck5: 'Please scan the QRIS on screen, total is set.',
    AppStrings.quickDeck6: 'Thank you, please wait a moment at pickup.',

    AppStrings.cafeDietaryAlertTitle: 'Food Safety & Allergy Alert',
    AppStrings.alertLactose: 'Lactose Intolerance (Use Oat/Soy)',
    AppStrings.alertDiabetes: 'Sugar Caution / Diabetic (0%)',
    AppStrings.alertNut: 'Extreme Nut Allergy (No Hazelnut/Almond)',
    AppStrings.alertDairy: 'Cow Milk Allergy (Plant Milk Only)',
    AppStrings.alertMaag: 'Acid Sensitive / Gastritis (Low-Acid Pick)',

    AppStrings.cafeTicketTitle: 'Cafe Order Ticket',
    AppStrings.cafeSubtotal: 'Subtotal',
    AppStrings.cafeTax: 'PB1 Tax (10%)',
    AppStrings.cafeGrandTotal: 'Grand Total',
    AppStrings.cafePaymentQris: 'Visual QRIS',
    AppStrings.cafePaymentCash: 'Cash Payment',
    AppStrings.cafeAmountReceived: 'Amount Received',
    AppStrings.cafeChange: 'Change to Return',
    AppStrings.cafeTranslateBill: 'Translate Bill to Sign & Speech',

    AppStrings.cafeWaitingChallengeTitle: 'Learn 1 Coffee Sign While You Wait',
    AppStrings.cafeWaitingChallengeDesc:
        'Practice on camera and receive barista appreciation!',
    AppStrings.cafeTryCamera: 'Practice on Camera',
    AppStrings.cafeChallengeSuccess: 'Awesome! Your gesture is verified!',
    AppStrings.cafeHoldGuide: 'Hold gesture in front of camera...',

    AppStrings.cafeCoffeeDetailTitle: 'Coffee Recipe Detail',
    AppStrings.cafeSendToCashier: 'Send to Cashier Counter',
    AppStrings.cafeDualViewCustomer: 'Customer View',
    AppStrings.cafeDualViewCashier: 'Cashier View',
    AppStrings.cafeQueueNumber: 'Queue Number',
    AppStrings.cafeCompositionOat: 'Creamy Oat Milk',
    AppStrings.cafeCompositionFoam: 'Silky Microfoam',
    AppStrings.cafeCompositionEspresso: 'Arabica Gayo Espresso',

    AppStrings.cafeLiveOrderCameraTitle: 'Live Camera & Voice Order',
    AppStrings.cafeLiveOrderCameraHint:
        'Direct sign gestures or voice orders to cashier',
    AppStrings.cafeSpellingCameraTitle: 'Cup Name Spelling Camera',
    AppStrings.cafeSpellingCameraHint:
        'Perform fingerspelling alphabet letters one by one',
    AppStrings.cafeChallengeHintBtn: 'View Sign Example',
    AppStrings.cafeChallengeCloseCamera: 'Close Camera',
    AppStrings.cafeSwitchCamera: 'Switch Camera',
    AppStrings.cafeDetectedLetter: 'Detected Letter',
    AppStrings.cafeHoldConfirming: 'Holding gesture...',
    AppStrings.cafeCameraActive: 'Camera Active',
    AppStrings.cafeOpenLiveCamera: 'Open Sign Camera',
    AppStrings.cafeCloseLiveCamera: 'Close Sign Camera',
    AppStrings.cafeDeleteOrderTitle: 'Remove Item?',
    AppStrings.cafeDeleteOrderConfirm:
        'Are you sure you want to remove @name from the order ticket?',
    AppStrings.cafeDeleteItem: 'Remove',
    AppStrings.cafeForCustomerName: 'For customer: @name',
    AppStrings.cafeSignVideoReady: 'SIGN VIDEO PLAYING: "ORDER READY"',
    AppStrings.cafeCloseNotification: 'Close Notification',
    AppStrings.cafeTrophyTitle: 'Cafe Sign Star!',
    AppStrings.cafeTrophyDesc: 'Awesome! You performed the "@sign" gesture perfectly. The barista really appreciates your effort!',
    AppStrings.cafeTrophyAction: 'Awesome!',

    AppStrings.cafeEmptyTicket: 'No items in the order ticket yet.',
    AppStrings.cafeCustomerNotesPrefix: 'Customer Choice: @notes',
    AppStrings.cafeSubstituteOatMilk: 'Switch to Oat Milk (Lactose-Free)',
    AppStrings.cafeExactCash: 'Exact Cash',
    AppStrings.cafeCompleteCashPayment: 'Complete Cash Payment',
    AppStrings.cafeQrisNationalStandard: 'NATIONAL PAYMENT STANDARD',
    AppStrings.cafeQrisVerifying: 'Processing Verification...',
    AppStrings.cafeQrisSimulatePay: 'Simulate QRIS Payment Now',
    AppStrings.cafePaymentSuccessServing: 'Payment Successful • Ready to Serve',
    AppStrings.cafeResetTicketTooltip: 'New Order / Reset Ticket',
    AppStrings.cafeTranscriptInputHint: 'Type or speak order...',
    AppStrings.cafeProcessOrder: 'Process',
    AppStrings.cafeListeningVoiceNow: 'LISTENING FOR VOICE (SPEAK NOW)...',
    AppStrings.cafeSimulatorTranscriptTitle:
        'CAMERA / MICROPHONE TRANSCRIPT SIMULATOR',
    AppStrings.cafeQuickExamples: 'Quick Examples',
    AppStrings.cafeDetectedPrefix: 'Detected: @text',
    AppStrings.cafeQuickOrderAction: 'Order This',
    AppStrings.cafeCameraListeningGestures:
        'SIGN CAMERA ACTIVE (PERFORM ORDER GESTURES)...',
    AppStrings.cafeOpenMenuCatalog: 'Open Menu Catalog',

    AppStrings.cafeSignGuideTitle: 'Sign Guide: "@word"',
    AppStrings.cafeReadyToPractice: 'I am Ready to Practice on Camera',
    AppStrings.cafeChangeSignTooltip: 'Change to Another Sign',
    AppStrings.cafeChallengeTitle: 'Challenge: "@word"',
    AppStrings.cafeMatchPercentage: '@percent% Match',
    AppStrings.cafeTodaySignTitle: "TODAY'S SIGN:",
    AppStrings.cafeAimGestureHint: 'Point hand gesture towards the cafe camera',
    AppStrings.cafeTryAgain: 'Try Again',
    AppStrings.cafeHoldForLetter: 'Hold for "@letter"',
    AppStrings.cafeTouchToSpell: 'Tap letter to spell...',
    AppStrings.cafeDeleteLastLetter: 'Delete Last Letter',
    AppStrings.cafeOfficialReceipt: 'OFFICIAL CAFE RECEIPT',
    AppStrings.cafeSelect: 'Select',
    AppStrings.cashierGreetingPrompt:
        'Hello! What would you like to order today?',
    AppStrings.cashierScreenNormal: 'Normal (0°)',
    AppStrings.cashierSpeakThisText: 'Speak This Text',
    AppStrings.cafeSpellingHintUnlimited:
        'Sign letters or tap alphabet below. Tap Save Name when ready.',
    AppStrings.cafeCashierBaristaAiTitle: 'Cashier Desk & Barista AI',
    AppStrings.cafeQueueNumberPrefix: 'Queue Number: @queue',
    AppStrings.cafeClearTicketTooltip: 'Clear Ticket & Transcript',
    AppStrings.cafeBackTooltip: 'Back',

    // Queue Management
    AppStrings.cafeOrderQueueTitle: 'Order Queue',
    AppStrings.cafeOrderQueueSubtitle:
        'Orders currently preparing & awaiting pickup',
    AppStrings.cafeOrderQueueBadge: '@count in Queue',
    AppStrings.cafeOrderQueueEmpty: 'No Orders in Queue Yet',
    AppStrings.cafeOrderQueueEmptyDesc:
        'Paid orders will automatically appear here for barista preparation.',
    AppStrings.cafeStartNextOrder: 'Record Next Customer Order',
    AppStrings.cafePaymentSuccessQueued:
        'Payment Paid! Order @queue Entered Queue',
    AppStrings.cafeViewQueue: 'View Queue (@count)',
    AppStrings.cafeFilterAll: 'All',
    AppStrings.cafeFilterPreparing: 'Preparing',
    AppStrings.cafeFilterReady: 'Ready for Pickup',
    AppStrings.cafeFilterCompleted: 'Completed',
    AppStrings.cafeMarkPreparing: 'Start Brewing',
    AppStrings.cafeMarkReady: 'Mark as Ready',
    AppStrings.cafeMarkCompleted: 'Handover / Done',
    AppStrings.cafeCallCustomerVoice: 'Voice Call (TTS)',
    AppStrings.cafeCallCustomerDeaf: 'Deaf Call (Vibe)',
    AppStrings.cafeOrderElapsedMinutes: '@minutes min ago',
    AppStrings.cafeOrderElapsedSeconds: 'Just now',

    // Sign Sentence Accumulator
    AppStrings.cafeSignSentenceBuilderTitle: 'Detected Sign Sentence',
    AppStrings.cafeDeleteLastWord: 'Delete Word',
    AppStrings.cafeClearSentence: 'Clear Sentence',
    AppStrings.cafeSentenceEmpty:
        'Perform sign gestures to build order sentence...',
    AppStrings.cafeWordDetected: 'Detected: @word',

    // Modern Menu Catalog & Input Bar
    AppStrings.cafeCatalogTitle: 'Modern Cafe Menu Catalog',
    AppStrings.cafeCatalogSubtitle:
        'Choose favorite drinks or customize barista recipe',
    AppStrings.cafeCatalogSearchHint:
        'Search coffee, aren latte, matcha, oat...',
    AppStrings.cafeCategoryAll: 'All Drinks',
    AppStrings.cafeCategoryMilkCoffee: 'Milk Coffee',
    AppStrings.cafeCategoryBlackCoffee: 'Black Coffee',
    AppStrings.cafeCategoryGentleStomach: 'Gentle Stomach',
    AppStrings.cafeCategoryNonCoffee: 'Non-Coffee',
    AppStrings.cafeCustomize: 'Customize',
    AppStrings.cafeQuickAdd: '+ Add',
    AppStrings.cafeMenuNotFound: 'Menu Not Found',
    AppStrings.cafeMenuNotFoundDesc:
        'Try another keyword or select a category above.',
    AppStrings.cafeResetSearch: 'Reset Search',
    AppStrings.cafeItemsAvailable: '@count drinks ready to order',
    AppStrings.cafeModeSignCamera: 'Sign Camera',
    AppStrings.cafeModeVoiceStt: 'Voice (Mic)',
    AppStrings.cafeModeMenuCatalog: 'Menu Catalog',
    AppStrings.cafeQuickPicksTitle: 'Quick Picks & Allergies',
    AppStrings.cafeClearInputTooltip: 'Clear Text',

    // Customer Voice Order & Cashier Sign Video
    AppStrings.cafeCustomerVoiceOrderTitle: 'Voice Coffee Order',
    AppStrings.cafeCustomerVoiceOrderSubtitle:
        'Speak to order, text can be edited before sending',
    AppStrings.cafeCustomerVoiceMicTap: 'Tap to Speak',
    AppStrings.cafeCustomerVoiceListening:
        'Listening... Please speak your order',
    AppStrings.cafeCustomerVoiceHint:
        'Your speech transcript appears here and can be edited directly',
    AppStrings.cafeCustomerVoiceEditHint: 'Edit order text if needed...',
    AppStrings.cafeCustomerVoiceSend: 'Send Order to Cashier',
    AppStrings.cafeCustomerVoiceSentSnackbar:
        'Order sent! Sign translation is playing on cashier screen.',
    AppStrings.cafeCustomerVoiceSignBadge:
        'Real-Time Sign Translation at Cashier',
    AppStrings.cafeCustomerQuickTagsTitle: 'Quick Preferences',
    AppStrings.cafeCashierSignVideoTitle: 'Order Sign Language Video',
    AppStrings.cafeCashierSignVideoSubtitle:
        'Real-time sign translation from customer voice',
    AppStrings.cafeCashierSignStandby: 'Ready for Sign Language',
    AppStrings.cafeCashierSignStandbyDesc: 'When customer orders via voice, sign language video will automatically appear here.',
    AppStrings.cafeCashierSignOfflineBadge: 'Offline (Asset)',
    AppStrings.cafeCashierSignCachedBadge: 'Offline (Cached)',
    AppStrings.cafeCashierSignOnlineBadge: 'Online CDN',
    AppStrings.cafeCashierSignDownload: 'Download Offline',
    AppStrings.cafeCashierSignDownloading: 'Downloading video...',
    AppStrings.cafeCashierSignWordChips: 'Sign Vocabulary Sequence',

    // Customer Mode Switch & Camera Sign Detection
    AppStrings.cafeCustomerModeMic: 'Voice (Mic)',
    AppStrings.cafeCustomerModeCamera: 'Sign Language',
    AppStrings.cafeCustomerCameraActiveTitle: 'Order Sign Language Detection',
    AppStrings.cafeCustomerCameraSubtitle:
        'Point camera at your hand to order with signs',
    AppStrings.cafeCustomerCameraReady: 'Ready — perform sign gesture',
    AppStrings.cafeCustomerDeleteLastWord: 'Delete Last Word',
    AppStrings.cafeCustomerClearSentence: 'Reset Signs',
    AppStrings.cafeCustomerQuickSignChips: 'Quick Sign Simulation:',
    AppStrings.cafeSignModelChanged: 'Sign language model switched to @model',

    // Sign Video Player Controls & Indicators
    AppStrings.signVideoPlay: 'Play',
    AppStrings.signVideoPause: 'Pause',
    AppStrings.signVideoReplay: 'Replay',
    AppStrings.signVideoLoop: 'Loop Playback',
    AppStrings.signVideoOfflineBadge: 'Offline Video',
    AppStrings.signVideoCachedBadge: 'Saved in Cache',
    AppStrings.signVideoOnlineBadge: 'Online CDN (Downloadable)',
    AppStrings.signVideoDownloadAction: 'Download Video',
    AppStrings.signVideoDownloading: 'Downloading video...',
    AppStrings.signVideoDownloadingTitle: 'Downloading Sign Video',
    AppStrings.signVideoDownloadingDesc:
        'Saving video to local cache for instant offline access',
    AppStrings.signVideoDownloadComplete: 'Download Complete',
    AppStrings.signVideoStatusPlaying: 'Playing',
    AppStrings.signVideoStatusPaused: 'Paused',

    // Cafe Cashier Control Sheet
    AppStrings.cafeMenuMoreTooltip: 'Cashier Controls & Menu',
    AppStrings.cafeControlSheetTitle: 'Cashier Controls',
    AppStrings.cafeControlSheetSubtitle:
        'Sign language model, queue, and table session',
    AppStrings.cafeControlSignModelTitle: 'Sign Language Model',
    AppStrings.cafeControlSignModelDesc:
        'Active sign standard for camera and video translation',
    AppStrings.cafeControlBisindoDesc:
        'Indonesian Sign Language (2 Hands / Natural)',
    AppStrings.cafeControlSibiDesc: 'Indonesian Sign System (1 Hand / Formal)',
    AppStrings.cafeControlQueueTitle: 'Cafe Orders Queue',
    AppStrings.cafeControlQueueDesc: '@count active orders in queue',
    AppStrings.cafeControlQueueOpen: 'Open Queue',
    AppStrings.cafeControlStaffTitle: 'Staff Security & PIN',
    AppStrings.cafeControlStaffLoggedIn: 'Verified Cashier Staff',
    AppStrings.cafeControlStaffLocked: 'Locked (Staff PIN Required)',
    AppStrings.cafeControlStaffLogin: 'Enter PIN',
    AppStrings.cafeControlStaffLogout: 'Log Out',
    AppStrings.cafeControlResetTitle: 'Reset Transaction & New Table',
    AppStrings.cafeControlResetDesc:
        'Clear current bill and return to standby state',
    AppStrings.cafeControlResetConfirm: 'Are you sure you want to reset this table? Unsaved items will be cleared.',
    AppStrings.cafeControlResetCancel: 'Cancel',

    // Customer Side Menu Catalog Banner
    AppStrings.cafeCustomerMenuBannerTitle: 'Complete Menu Catalog',
    AppStrings.cafeCustomerMenuBannerSubtitle:
        'Browse coffee variants, gentle plant milk, & snacks',
    AppStrings.cafeCustomerMenuBannerButton: 'Open Menu',

    // Coffee Detail Screen Order Sent Dialog
    AppStrings.cafeOrderSentSuccessTitle: 'Order Successfully Sent!',
    AppStrings.cafeOrderSentSuccessDesc:
        'Your customized coffee has been added to the cashier & barista queue.',
    AppStrings.cafeOrderSentSignSyncNotice:
        'Automatically synced with cashier sign language video',
    AppStrings.cafeOrderSentConfirmButton: 'OK, Done',

    // Cashier Order Deck (3-Tab Deck: Bahasa Isyarat, 1-Tap, Mic)
    AppStrings.cafeCashierDeckTitle: 'Cashier Order & Communication',
    AppStrings.cafeCashierDeckSubtitle:
        'Customer sign detection, 1-tap quick actions, and voice input',
    AppStrings.cafeCashierTabSign: 'Sign Language',
    AppStrings.cafeCashierTabQuick: '1-Tap',
    AppStrings.cafeCashierTabMic: 'Voice (Mic)',
    AppStrings.cafeCashierCameraActiveTitle: 'Cashier Sign Detection',
    AppStrings.cafeCashierCameraSubtitle:
        'Camera is reading customer hand gestures in front of the counter',
    AppStrings.cafeCashierMicTap: 'Tap to Speak (Cashier)',
    AppStrings.cafeCashierMicListening: 'Listening to cashier...',
    AppStrings.cafeCashierMicHint:
        'Your speech will be converted to text and sign language video',
    AppStrings.cafeCashierSubmitOrder: 'Process Order to Ticket',
    AppStrings.cafeCashierSubmitEmptyWarning:
        'Please use sign language, 1-tap, or speech to order first.',
    AppStrings.cafeCashierSubmitSuccess:
        'Order successfully confirmed to transaction ticket!',

    // Flip & Device Mode
    AppStrings.cafeFlipScreen: 'Flip Screen 180°',
    AppStrings.cafeFlipTooltip: 'Flip screen 180° to face customer',
    AppStrings.cafeDeviceModeTitle: 'Cashier Device Mode',
    AppStrings.cafeDeviceModeDesc: 'Select tablet setup for cashier & customer',
    AppStrings.cafeMode1Tablet: '1 Tablet (Flip 180°)',
    AppStrings.cafeMode1TabletDesc:
        'Single shared tablet with 180° rotation facing customer',
    AppStrings.cafeMode2Tablet: '2 Tablets (Room Sync)',
    AppStrings.cafeMode2TabletDesc:
        'Two tablets synced in real-time via room code',
    AppStrings.cafeRoomCodeLabel: 'Counter Room Code',
    AppStrings.cafeRoomCodeHint: 'e.g., KAFE-01',
    AppStrings.cafeCreateRoom: 'Create New Room',
    AppStrings.cafeJoinRoom: 'Connect Room',
    AppStrings.cafeRoomCreated: 'Room created and synced successfully',
    AppStrings.cafeRoomJoined: 'Connected to cashier room successfully',
    AppStrings.cafeRoomCodeCopied: 'Room code copied to clipboard',
    AppStrings.cafeFlipActive: 'Screen rotated 180° facing customer',
    AppStrings.cafeFlipInactive:
        'Screen returned to standard cashier orientation',
    AppStrings.cafeCashierCameraClosedTitle: 'Sign Detection Camera Ready',
    AppStrings.cafeCashierCameraClosedDesc: 'Camera is closed for battery saving and privacy. Open camera when ready to order with sign language.',
    AppStrings.cafeCashierCameraClosedBadge: 'Camera Off',

    // Dual Tablet PIN Role Separation
    AppStrings.cafeDualStaffHostTitle: 'Cashier Tablet (Room Host)',
    AppStrings.cafeDualStaffHostDesc: 'This tablet acts as Cashier Counter. Share this room code with the Customer Tablet.',
    AppStrings.cafeDualCustomerTitle: 'Customer Tablet (Facing Display)',
    AppStrings.cafeDualCustomerDesc:
        'Enter the room code from the cashier to connect this tablet.',
    AppStrings.cafeDualCustomerConnected: 'Connected to Cashier Counter',
    AppStrings.cafeDualStaffLoginPrompt:
        'Is this cashier tablet? Enter Staff PIN',
    AppStrings.cafeDualHostBadge: 'CASHIER HOST',
    AppStrings.cafeDualCustomerBadge: 'CUSTOMER DISPLAY',

    // Stage Advance Bottom Action Bar
    AppStrings.cafeStageAdvanceNaming: 'Proceed: Name & Pay',
    AppStrings.cafeStageAdvanceNamingWithCount:
        'Proceed: Name & Pay (@count items)',
    AppStrings.cafeStageAdvancePickup: 'Proceed: Pick Up Coffee',
    AppStrings.cafeStageWaitingPayment: 'Waiting for Payment',
    AppStrings.cafeStageOrderCompleted: 'Done & New Order',

    // Menu Photo CRUD (Supabase Storage)
    AppStrings.cafeMenuPhotoChange: 'Change Menu Photo',
    AppStrings.cafeMenuPhotoCamera: 'Take from Camera',
    AppStrings.cafeMenuPhotoGallery: 'Choose from Gallery',
    AppStrings.cafeMenuPhotoUploading: 'Uploading menu photo...',
    AppStrings.cafeMenuPhotoUploadSuccess: 'Menu photo updated successfully!',
    AppStrings.cafeMenuPhotoUploadFailed: 'Failed to upload menu photo',
  };
}
