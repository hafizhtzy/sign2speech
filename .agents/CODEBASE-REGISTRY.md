# 🗂️ Katalog & Indeks Kode Terpusat: Sign2Speech (`/core`, `/common`, & `Services`)

> **PANDUAN HEMAT TOKEN UNTUK AI AGENT (MANDATORY WRITE-THROUGH INDEX):**
> 1. **BACA FILE INI DULU SEBELUM NGODING:** Sebelum membuat widget, tombol, card, helper, formatter, dialog, atau service baru, **baca tabel di bawah ini**. Jika sudah ada, langsung `import` dan panggil sesuai *Signature*-nya **tanpa perlu membuka/membaca isi file kodingannya** (sangat menghemat kuota token).
> 2. **WAJIB UPDATE SAAT MENAMBAH / MENGUBAH / MENGHAPUS:** Setiap kali Anda menambahkan, mengubah signature/parameter/return, atau menghapus item di `/core`, `/common`, atau `Services/Repositories`, Anda **WAJIB memperbarui tabel di file ini pada giliran yang sama**.
> 3. **FORMAT HEMAT TOKEN (ULTRA-COMPACT):** Tulis **1 baris per item** (`Nama | Lokasi File | Signature | Kegunaan 1 Kalimat`).

---

## 1. Kategori `/core` — Infrastruktur, Tema, & Pondasi Aplikasi

| Nama Class / Modul | Lokasi File (`Path`) | Signature Utama (`Method / Getter -> Return`) | Kegunaan Singkat (1 Kalimat) |
| :--- | :--- | :--- | :--- |
| `AppColors` | `lib/core/theme/app_colors.dart` | `.primary, .secondary, .canvas, .surface, .bgSurface, .ink, .muted, .matcha, .amber` -> `Color` | Token warna semantik tunggal (otomatis beralih Light "Cafe Warm Oat Milk" & Dark "Instagram AMOLED"). |
| `AppTypography` | `lib/core/theme/app_typography.dart` | `.displayLarge/.Medium/.Small, .headlineLarge/.Medium/.Small, .titleLarge/.Medium/.Small, .bodyLarge/.Medium/.Small, .labelLarge/.Medium/.Small` -> `TextStyle` | Hirarki tipografi Google Fonts Plus Jakarta Sans tunggal proyek; modifikasi hanya via `.copyWith()`. |
| `AppTheme` | `lib/core/theme/app_theme.dart` | `AppTheme.lightTheme`, `AppTheme.darkTheme` -> `ThemeData` | Konfigurasi ThemeData resmi Material 3 terpadu untuk tema terang dan gelap aplikasi. |
| `AppStrings` | `lib/core/localization/app_strings.dart` | Kunci teks string UI statis (contoh: `AppStrings.save`, `AppStrings.startNow`, `AppStrings.orderQueue`) | Single Source of Truth kunci lokalisasi; wajib dipanggil dengan getter reaktif `.tr` di widget. |
| `AppTranslations` | `lib/core/localization/app_translations.dart` | `Map<String, Map<String, String>> keys` (`id_ID`, `en_US`) | Kamus terjemahan bilingual resmi aplikasi untuk GetX reactive multi-language. |
| `SupabaseResult<T>` | `lib/core/supabase/supabase_result.dart` | `SupabaseSuccess(data)`, `SupabaseFailure(errorMessage, error)` | Sealed class Dart 3 untuk pemodelan hasil operasi Supabase data layer yang aman dan exhaustive. |
| `AppRoutes` | `lib/core/constants/app_routes.dart` | `initial, home, cafeCashier, signTranslate, history, settings` -> `String` | Daftar rute navigasi aplikasi terpusat untuk GetX routing system. |
| `AppAssets` | `lib/core/constants/app_assets.dart` | Konstanta path gambar/ikon di assets (ilustrasi 2D editorial) | Single Source of Truth path aset visual agar tidak hardcoded string di widget. |

---

## 2. Kategori `/core/widgets` & `/common/widgets` — Komponen UI Pakai Ulang (Shared UI)

| Nama Komponen / Widget | Lokasi File (`Path`) | Parameter Utama (`Props / Args`) | Kegunaan Singkat (1 Kalimat) |
| :--- | :--- | :--- | :--- |
| `AppPrimaryButton` | `lib/core/widgets/app_button.dart` | `({required String label, VoidCallback? onPressed, bool isLoading, IconData? icon, double height = 50})` | Tombol aksi utama (StadiumBorder, touch target $\ge 48\text{dp}$, loading indicator terpadu). |
| `AppSecondaryButton` | `lib/core/widgets/app_button.dart` | `({required String label, VoidCallback? onPressed, IconData? icon, double height = 50})` | Tombol aksi sekunder bergaris (OutlinedButton dengan warna border & ink dinamis). |
| `AppCard` | `lib/core/widgets/app_card.dart` | `({required Widget child, Color? backgroundColor, BorderSide? border, VoidCallback? onTap, double borderRadius = 16})` | Kartu elevasi taktil responsif dengan rounded corner 16dp dan touch feedback splash. |
| `AppSnackbar` | `lib/core/widgets/app_snackbar.dart` | `AppSnackbar.show({required String title, required String message, SnackbarVariant variant, IconData? icon})` | Snackbar aksesibel dengan kontras tinggi $\ge 7:1$ WCAG AA untuk varian info, success, warning, dan error. |
| `EmptyStateView` | `lib/core/widgets/empty_state_view.dart` | `({required String title, required String subtitle, String? actionLabel, VoidCallback? onAction, String? imagePath, IconData? icon})` | Tampilan standar saat data/list kosong beserta ilustrasi, deskripsi, tombol CTA, dan anti-overflow. |
| `ResponsiveContentWrapper` | `lib/core/widgets/responsive_layout.dart` | `({required Widget child, double maxWidth = 1140, EdgeInsetsGeometry padding})` | Pembungkus konten yang membatasi lebar form/dashboard di layar lebar (Tablet & Desktop). |
| `AdaptiveLayout` | `lib/core/widgets/responsive_layout.dart` | `({required WidgetBuilder compact, WidgetBuilder? medium, WidgetBuilder? expanded})` | Builder layout adaptif berbasis lebar kontainer (bukan sekadar full screen window). |
| `CashierFab` | `lib/core/widgets/cashier_fab.dart` | `({required VoidCallback onPressed, bool isExpanded})` | Floating Action Button melayang untuk akses cepat kasir kafe & bantuan. |
| `StatusBadge` | `lib/core/widgets/status_badge.dart` | `({required String label, required Color color, IconData? icon})` | Chip/badge indikator status (aktif, offline/matcha, pending, selesai). |
| `PaginationControlBar` | `lib/presentation/widgets/pagination_control_bar.dart` | `({required int currentPage, required int totalPages, required int totalItems, int itemsPerPage = 12, required ValueChanged<int> onPageChanged})` | Bilah navigasi pagination adaptif dengan kontrol Prev/Next, nomor halaman, touch target $\ge 48\text{dp}$, dan info item. |

---

## 3. Kategori `/core/utils` & Extension Helpers

| Nama Fungsi / Helper | Lokasi File (`Path`) | Signature (`Input Params -> Return Type`) | Kegunaan Singkat (1 Kalimat) |
| :--- | :--- | :--- | :--- |
| `AppCurrencyFormatter` / `formatRupiah` | `lib/core/utils/currency_formatter.dart` | `format(num amount, {bool withSymbol = true}) -> String` | Mengubah angka ke format Rupiah standar Indonesia (misal `Rp 15.000` atau `15.000`). |
| `ResponsiveContext` | `lib/core/widgets/responsive_layout.dart` | `context.isCompact, context.isMedium, context.isExpanded, context.isLargeScreen -> bool` | Extension helper pada BuildContext untuk mendeteksi breakpoint layar (Compact <600dp, Medium 600-839dp, Expanded >=840dp). |

---

## 4. Kategori `Services & Repositories` — Layanan Bisnis & Data

| Nama Service / Repo | Lokasi File (`Path`) | Method Utama (`Signature -> Return Type`) | Kegunaan Singkat (1 Kalimat) |
| :--- | :--- | :--- | :--- |
| `SupabaseCafePosService` | `lib/features/cafe_pos/data/datasources/supabase_cafe_pos_service.dart` | `fetchMenuItems(), createOrder(order), updateOrderStatus(...) -> Future<SupabaseResult<T>>` | Layanan transaksi POS kasir kafe, pesanan kopi, dan manajemen status tiket order ke Supabase. |
| `CafeMenuStorageService` | `lib/features/cafe_pos/data/datasources/cafe_menu_storage_service.dart` | `uploadMenuPhoto(file), getMenuPhotoUrl(path) -> Future<String?>` | Layanan upload dan cache foto menu kopi ke Supabase Storage bucket `menu-photos`. |
| `SupabaseCounterSessionService` | `lib/features/cafe_pos/data/datasources/supabase_counter_session_service.dart` | `openSession(), closeSession(), getActiveSession() -> Future<SupabaseResult<CafeCounterSession>>` | Layanan manajemen sesi meja kasir kafe dan status counter aktif. |
| `SupabaseHistoryService` | `lib/features/history/services/supabase_history_service.dart` | `getHistory(), addHistoryItem(item), deleteHistoryItem(id) -> Future<SupabaseResult<List<HistoryItem>>>` | Layanan sinkronisasi riwayat terjemahan isyarat dan transaksi ke Supabase. |
| `BisindoClassifierService` | `lib/features/sign_language/services/bisindo_classifier_service.dart` | `classifyFrame(landmarks) -> BisindoPrediction` | Mesin inferensi TFLite lokal untuk klasifikasi gesture isyarat BISINDO secara real-time. |
| `BisindoTtsService` | `lib/features/sign_language/services/bisindo_tts_service.dart` | `speak(text), stop(), setQueue(queue) -> Future<void>` | Layanan Text-to-Speech serial FIFO untuk menyuarakan hasil deteksi isyarat BISINDO dalam Bahasa Indonesia. |
| `CameraFeedService` | `lib/features/sign_language/services/camera_feed_service.dart` | `initialize(), startStream(onFrame), stopStream() -> Future<void>` | Bridging CameraX Android native ke Flutter EventChannel untuk streaming frame kamera tanpa lag. |
| `SpeechService` | `lib/features/translator/services/speech_service.dart` | `listen({onResult, onError}), stopListening() -> Future<void>` | Layanan Speech-to-Text lokal bahasa Indonesia (`id-ID`) untuk menangkap suara pengguna/kasir. |
