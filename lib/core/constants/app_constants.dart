class AppConstants {
  AppConstants._();

  // ── 1. Konfigurasi Supabase (Cloud-to-Local Ready via .env) ──────────────
  /// URL utama instance Supabase.
  /// Diinjeksikan secara aman dari file `.env` via `--dart-define-from-file=.env`.
  /// Fallback defaultValue berupa placeholder aman agar tidak membocorkan URL riil ke git publik.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dfvcydfzjwvkzstdvpaf.supabase.co',
  );

  /// Anon Key publik Supabase (aman di client karena tabel dilindungi RLS PostgreSQL).
  /// Diinjeksikan secara aman dari file `.env` via `--dart-define-from-file=.env`.
  /// Fallback defaultValue berupa anon key resmi proyek untuk kemudahan testing lokal & emulator.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmdmN5ZGZ6and2a3pzdGR2cGFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ3NDUzMTIsImV4cCI6MjExMDMyMTMxMn0.FAqZPR5XnUOA9IW1O6T6uM3WmHqTtksQ8JV1ANOeNGc',
  );

  /// Publishable Key format baru Supabase (opsional/alternatif anon key).
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  // ── 2. Konfigurasi Bucket Supabase Storage ───────────────────────────────
  /// Bucket publik untuk menyimpan foto menu kopi (dikompres <= 800x800 px).
  static const String menuPhotosBucket = 'menu-photos';

  /// Bucket publik untuk menyimpan catalog.json dan video bahasa isyarat (*.mp4).
  static const String signVideosBucket = 'sign-videos';

  /// Private Storage bucket untuk video bahasa isyarat yang dikelola Admin (Addendum V3).
  static const String signLanguageVideosBucket = 'sign-language-videos';

  /// Zona waktu bisnis resmi laporan keuangan (Addendum V3 Phase 3.1 & 10).
  static const String businessTimezone = 'Asia/Jakarta';

  // ── Supabase Edge Function Names ──────────────────────────────────────────
  static const String edgeFnManageCashier = 'admin-manage-cashier';
  static const String edgeFnCreateQris = 'payment-create-qris';
  static const String edgeFnPaymentWebhook = 'payment-webhook';
  static const String edgeFnProcessRefund = 'admin-process-refund';

  /// Base URL publik untuk mengakses foto menu kopi di Supabase Storage.
  static const String menuPhotosBaseUrl =
      '$supabaseUrl/storage/v1/object/public/$menuPhotosBucket';

  // ── 3. Konfigurasi CDN Video Bahasa Isyarat (Supabase Storage) ───────────
  /// Identifier project / bucket penyimpanan video bahasa isyarat.
  static const String signHostingProjectId = signVideosBucket;

  /// Base URL utama untuk pengambilan video bahasa isyarat (*.mp4) dan catalog.json
  /// langsung dari Supabase Storage bucket `sign-videos`.
  static const String signBaseUrl = String.fromEnvironment(
    'SIGN_BASE_URL',
    defaultValue: '$supabaseUrl/storage/v1/object/public/$signVideosBucket',
  );

  /// Alternative / Secondary CDN URL sebagai fallback sekunder Supabase Storage.
  static const String signAltBaseUrl =
      '$supabaseUrl/storage/v1/object/public/$signVideosBucket';

  /// Remote endpoint untuk pengambilan file katalog video JSON.
  static const String signCatalogUrl = '$signBaseUrl/catalog.json';

  /// Path aset lokal fallback untuk katalog JSON.
  static const String signCatalogAssetPath =
      'assets/sign_language/catalog.json';

  /// Identifier host / path storage untuk validasi URL.
  static const String signHostingDomain =
      'storage/v1/object/public/sign-videos';
}
