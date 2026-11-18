# Panduan & Aturan Agent: Proyek Flutter Sign2Speech

Dokumen ini adalah aturan resmi tingkat proyek (*Project Rule & Modern Architecture Constitution*) untuk Google Antigravity dan agen AI dalam pengembangan aplikasi **Sign2Speech** (`speech2sign`). Aturan ini wajib dipatuhi oleh seluruh agen dan subagen selama mengerjakan proyek.

---

## 0. GERBANG WAJIB SEBELUM NGODING / UBAH / UPDATE / TAMBAH / AUDIT KODE (HARD GATE)

> **ATURAN MUTLAK (ZERO-CODE WITHOUT SKILL & RULE):**
> Agen AI dan subagen **DILARANG KERAS** mulai menulis kode (`write_file`), mengubah/mengupdate kode (`edit_file`), memperbaiki bug, menambahkan fitur baru, atau melakukan audit kode **SEBELUM menemukan, membaca (`read_file`), dan menerapkan `SKILL.md` serta file aturan (`.agents/rules/*.md`) yang sesuai dengan fitur/domain tugas!**

1. **Wajib Baca Skill & Rules Terlebih Dahulu:**
   - **Tugas Supabase (Database, Query, RLS, Realtime, Storage Bucket `menu-photos`/`sign-videos`):** WAJIB baca [.agents/skills/supabase-postgres-best-practices/SKILL.md](file:///c:/fadli/project/sign2speech/.agents/skills/supabase-postgres-best-practices/SKILL.md) dan [.agents/rules/supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md) sebelum menyentuh kode!
   - **Tugas UI/UX, Widget, Layar Baru, Tema, atau Responsif:** WAJIB baca [.agents/rules/ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md) serta `SKILL.md` terkait (`ui-ux-pro-max`, `flutter-build-responsive-layout`, `flutter-responsive`, `ui-states`) sebelum mengedit widget!
   - **Tugas Debugging Bug / Error / Layar Putih / Overflow:** WAJIB baca `SKILL.md` dari `systematic-debugging` dan `flutter-fix-layout-issues` / `dart-fix-runtime-errors` sebelum mencoba memperbaiki kode!
   - **Tugas Arsitektur, Controller GetX, & State Management:** WAJIB baca `SKILL.md` dari `flutter-apply-architecture-best-practices` dan `agency-software-architect`!
   - **Tugas Voice AI (STT/TTS) & Kamera/TFLite/MediaPipe:** WAJIB baca `SKILL.md` dari `voice-ai-engine-development`, `android-dev`, `performance-profiling`, dan `dart-setup-ffi-assets`!
   - **Tugas Testing & Audit Kode/Keamanan:** WAJIB baca `SKILL.md` dari `test-driven-development`, `agency-code-reviewer`, `security-predeploy-gate`, dan `verification-before-completion`!
2. **Jika Belum Menemukan Skill yang Pas:**
   - **DILARANG langsung ngoding!** Cari terlebih dahulu di katalog `.agents/skills/` atau baca `skill-advisor` dan `using-superpowers` sampai menemukan skill yang tepat.
   - Panduan lengkap gerbang wajib ini tercantum di [.agents/rules/mandatory-skill-invocation-gate.md](file:///c:/fadli/project/sign2speech/.agents/rules/mandatory-skill-invocation-gate.md).

---

## 1. Standar Arsitektur Modern Dart & Flutter (Modern SDK Standards)

### A. Wajib Sintaks Dart Modern Terbaru
1. **Dot Shorthands & Type Inference:**
   - Gunakan dot shorthands untuk enum, alignment, dan konstruktor kontekstual seperti `.center`, `.none`, `.zero`, `.symmetric(...)` jika tipe target sudah inferable oleh kompilator Dart.
2. **Pattern Matching & Switch Expressions:**
   - Seluruh conditional matching yang kompleks, inspeksi tipe, destructuring record/map/list, dan status respons API wajib menggunakan **Dart 3 switch expressions** dan pattern matching exhaustiveness:
   ```dart
   final message = switch (result) {
     SupabaseSuccess(:final data) => 'Berhasil: ${data.length} item',
     SupabaseFailure(:final error) => 'Gagal: $error',
   };
   ```
3. **Data Classes & Sealed Classes:**
   - Gunakan `sealed class` untuk representasi state (State Modeling) dan model domain polimorfik.
4. **Hindari Legacy Boilerplate:**
   - Terapkan primary constructors, pattern assignment `final (x, y) = getCoordinates();`, dan inline if/collection-for secara deklaratif.

### B. Kompatibilitas Penuh WebAssembly (Wasm)
Jika project dikompilasi atau mendukung target Web:
1. **Dilarang Keras Menggunakan Legacy Web Libraries:**
   - **DILARANG KERAS** mengimpor `dart:html`, `dart:js`, atau `package:js`.
2. **Wajib Gunakan Modern Web Interop:**
   - Wajib menggunakan `package:web` dan `dart:js_interop` untuk seluruh interaksi DOM, Web APIs, audio context, dan window bindings.
3. **Standar Build Web:**
   - Build web wajib kompatibel dengan kompilasi Wasm (`flutter build web --wasm`) dan **WAJIB menyertakan flag `--web-content-hash`** untuk cache busting aset statis:
   ```bash
   flutter build web --wasm --web-content-hash
   ```

### C. Kamera & Visi Komputer (`flutter-mediapipe` / Native Vision Pipeline)
1. **Pondasi Arsitektur MediaPipe:**
   - Gunakan `flutter-mediapipe` (`mediapipe_vision` dan `mediapipe_core`) yang diintegrasikan dengan **Dart Build Hooks** (`hook/build.dart` & `hook/link.dart`) untuk kompilasi C/C++ native assets.
2. **Lifecycle & Anti-Memory Leak (Mandatory `.dispose()`):**
   - **WAJIB memanggil `.dispose()`** pada setiap instance detector/recognizer MediaPipe (`HandLandmarker`, `HolisticLandmarker`, `PoseLandmarker`) di dalam `onClose()` controller GetX atau lifecycle cleanup widget.
3. **Offloading Komputasi Frame:**
   - Komputasi landmark MediaPipe dan inferensi model MotionGRU/TFLite wajib dijalankan di background `Isolate` / compute worker agar *main thread UI* tetap stabil pada frame budget 60-120 FPS.

### D. Alur Pemrosesan AI Cerdas (`genkit`)
Jika aplikasi menambahkan fitur AI generatif tingkat lanjut, perbaikan tata bahasa isyarat-ke-teks, atau translasi cerdas berbasis konteks kafe:
1. **Definisi Flow Terstruktur:**
   - Wajib menggunakan **Firebase Genkit** (`genkit`) dengan pola deklaratif `ai.defineFlow(...)`.
2. **Skema & Type Safety:**
   - Setiap input dan output AI flow wajib didefinisikan menggunakan `@Schema()` / typed schema (TypeProvider) guna menjamin sanitasi output model dan mencegah *malformed JSON responses*.
3. **Observabilitas & Tracing:**
   - Manfaatkan Genkit telemetry and evaluation untuk memantau performa, latency, dan token cost.

### E. Gerbang Kualitas Statis Analyzer (Zero-Error & Zero-Deprecation Gate)
1. **Wajib `dart analyze`:**
   - Setiap selesai mengedit, menambah kode, atau melakukan refactoring, agen **WAJIB menjalankan `dart analyze`**.
2. **Standar Kelulusan:**
   - Kode harus menghasilkan **0 error** dan **0 deprecation warning**.
3. **Penanganan Deprecated Member:**
   - Jangan biarkan kode menggunakan API yang telah usang (*deprecated*). Segera ganti dengan API pengganti resmi.

---

## 2. Acuan Visual & Design System

1. **Sumber Kebenaran Visual (Single Source of Truth):**
   - **Palet Warna "Cafe Warm Oat Milk / Espresso" ([AppColors](file:///c:/fadli/project/sign2speech/lib/core/theme/app_colors.dart)):**
     - Primary: Rich Espresso Brown (`#2C1E18` / `AppColors.primary`)
     - Secondary / Active: Warm Caramel / Cinnamon (`#8C5A3C` / `AppColors.secondary`)
     - Canvas Background: Warm Oat Milk / Cream (`#FDFBF7` / `AppColors.canvas`)
     - Card / Surfaces: Pure White (`#FFFFFF` / `AppColors.surface`) & Latte Foam (`#F4EFE6` / `AppColors.bgSurface`)
     - Chips / Badges: Soft Latte Foam (`#F4EFE6` / `AppColors.paleMist`)
     - Ink / Headings: Deep Espresso (`#2C1E18` / `AppColors.ink`)
     - Muted Text: Roasted Mocha (`#6E5A4F` / `AppColors.muted`)
     - Borders: Warm Sand Border (`#E6DCD2` / `AppColors.border`)
     - Semantic Accents: Matcha Sage (`#4A6B53` / `AppColors.matcha` untuk offline & success), Amber Gold (`#D97724` / `AppColors.amber` untuk warning & highlight), Deep Espresso Dark (`#191210` / `AppColors.cameraDark` untuk kamera).
   - **Palet Warna "Instagram AMOLED Minimalist" (Dark Mode):**
     - True Black (`#000000` / `AppColors.darkCanvas`), Elevated Surface (`#1E1E1E` / `AppColors.darkBgSurface`), Card Surface (`#121212` / `AppColors.darkSurface`), Dark Border (`#262626` & `#2E2E2E`), Action White (`#F5F5F5`), Warm Caramel (`#D49B78`), Subtitle Grey (`#A8A8A8` & `#737373`).
     - **Dilarang Keras Menulis Raw Hex / Color:** Seluruh warna di widget wajib menggunakan `AppColors.<token>` dinamis.
   - **Tipografi Dinamis ([AppTypography](file:///c:/fadli/project/sign2speech/lib/core/theme/app_typography.dart)):** 
     - Google Fonts Plus Jakarta Sans untuk seluruh peran teks (Display, Headline, Title, Body, Label). Dilarang membuat `TextStyle(...)` tanpa melalui `AppTypography`.
   - **Multi-Bahasa Dinamis (Mandatory Dynamic Localization):**
     - Dilarang hardcode string teks antarmuka di widget! Seluruh teks antarmuka wajib didaftarkan di [AppStrings](file:///c:/fadli/project/sign2speech/lib/core/localization/app_strings.dart) dan diterjemahkan dalam dua bahasa di [AppTranslations](file:///c:/fadli/project/sign2speech/lib/core/localization/app_translations.dart) (`id_ID` & `en_US`).
     - Gunakan getter `.tr` reaktif di dalam `Obx(() => ...)` agar UI langsung berganti bahasa tanpa restart aplikasi saat diubah di Pengaturan.
   - **Aturan Lengkap:** Wajib patuhi panduan terstruktur di [.agents/rules/ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md).
   - **Ilustrasi Karakter:** Karakter editorial 2D dengan garis Espresso (`#2C1E18`) dan fill putih hangat.
2. **Aturan Baku Responsif Multi-Device (Mandatory Multi-Device Responsiveness):**
   - **Wajib Responsif di Setiap Pembuatan/Perbaikan Komponen:** Setiap kali memperbaiki, memodifikasi, atau membuat halaman (*page*), widget, dialog, bottom sheet, atau komponen baru, Antigravity **WAJIB membuatnya responsif di berbagai perangkat** (Smartphone/Compact `< 600 dp`, Tablet/Foldable/Medium `600-839 dp`, Desktop/Expanded `≥ 840 dp`).
   - **Batasan Lebar Maksimal:** Gunakan `ResponsiveContentWrapper` / `ConstrainedBox` (`maxFormWidth: 580 dp`, `maxContentWidth: 960 dp`, `maxDashboardWidth: 1140 dp`) agar konten tidak melebar abnormal di tablet/desktop.
   - **Proteksi Overflow:** Setiap layar scrollable wajib menggunakan `SingleChildScrollView(physics: BouncingScrollPhysics())` untuk mencegah *RenderFlex overflow*.
   - **Teks Dinamis:** Wajib dibungkus `Expanded`/`Flexible` dengan `overflow: TextOverflow.ellipsis` di dalam `Row`.
   - **Grid Adaptif:** Gunakan `SliverGridDelegateWithMaxCrossAxisExtent` (hindari fixed `crossAxisCount`).
   - **Touch Target:** Seluruh elemen interaktif wajib memenuhi standar touch target minimum **$\ge 48\times 48$ dp**.

---

## 3. Arsitektur Kode & State Management

1. **State Management & DI:**
   - Proyek ini secara resmi menggunakan **Flutter + GetX** (`GetxController`, `Bindings`, `GetView`/`GetWidget`).
   - **Dilarang keras mengganti state management secara sepihak** (misalnya memaksakan migrasi ke BLoC, Riverpod, atau Provider) meskipun ada skill umum yang merekomendasikan hal tersebut.
2. **Clean Architecture 3-Lapisan:**
   - **Presentation Layer (`ui/` atau `presentation/`):** View dan GetxController. Tidak boleh ada dependensi `BuildContext` di luar widget tree atau di dalam domain/data layer.
   - **Domain Layer (`domain/`):** Entitas murni dan interface repository tanpa dependensi framework UI.
   - **Data Layer (`data/`):** Implementasi repository, data source (MediaPipe native event channel, TFLite Flutter, FIFO TTS queue, STT, tiered video cache).
3. **Versi Dependensi & Dependency Lock:**
   - Gunakan selalu dokumentasi yang sesuai dengan versi dependensi riil di [pubspec.yaml](file:///c:/speech2sign/pubspec.yaml) dan [pubspec.lock](file:///c:/speech2sign/pubspec.lock) (Flutter 3.50.x, Dart 3.14.x).
   - Dilarang menambah package baru tanpa izin eksplisit pengguna.
4. **Batas 500 Baris Kode (500-LOC Confirmation Gate):**
   - File controller, view, dan service wajib modular ($\le 300 - 450$ baris).
   - Jika file akan melampaui $\pm 500$ baris, agen **WAJIB meminta konfirmasi terlebih dahulu** kepada pengguna sebelum memecah file.

---

## 4. Pembagian Peran & Pemanggilan Skill

Muat persona agent atau skill secara spesifik sesuai tugas (*progressive disclosure*), jangan memuat seluruh katalog sekaligus:

| Kategori Tugas | The Agency Agent (Persona) | Agentic Awesome Skill (Prosedur) | Panduan Penggunaan |
| :--- | :--- | :--- | :--- |
| **Arsitektur Sistem** | `agency-software-architect` | `flutter-apply-architecture-best-practices` | Kawal pemisahan Presentation, Domain, Data. Domain murni bebas GetX/UI; Controller bebas BuildContext. |
| **Implementasi Flutter & Mobile** | `agency-mobile-app-builder` | `flutter-expert`, `mobile-developer`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues` | Implementasi widget GetX, layout responsif, touch target >= 48 dp, dan bridging CameraX EventChannel. |
| **Modern Dart & FFI/Hooks** | `agency-software-architect` | `dart-use-pattern-matching`, `dart-setup-ffi-assets`, `dart-use-ffigen` | Terapkan pattern matching Dart 3, switch expressions, dan Native Assets hooks. |
| **Integrasi Voice AI (STT/TTS)** | `agency-voice-ai-integration-engineer` | `voice-ai-engine-development` | Kelola STT `id-ID`, antrean serial FIFO TTS, buffer ejaan alfabet 1500ms. Dilarang switch ke cloud/Whisper tanpa izin. |
| **Desain UI/UX & Visual** | `agency-ui-designer`, `agency-ux-architect` | `ui-ux-pro-max`, `design-system` | Acuan mutlak `DESIGN.md` (Cafe Warm Oat Milk / Espresso), font Plus Jakarta Sans, dan aset `assets/komponen_img/`. |
| **Aksesibilitas Universal** | `agency-accessibility-auditor` | `screen-reader-testing`, `accessibility-compliance-accessibility-audit` | Evaluasi kontras WCAG, touch target minimum 48 dp, dan uji screen reader. |
| **Code Review & Mutu Kode** | `agency-code-reviewer` | `code-review-checklist`, `code-review-excellence`, `requesting-code-review` | Periksa disposal controller/stream di `onClose()`, race condition token `_playSessionId`, dan sanitasi numerik. |
| **Testing & Otomasi QA** | `agency-test-automation-engineer` | `test-driven-development`, `flutter-add-widget-test`, `verification-before-completion` | Jalankan alur TDD, tulis tes gagal -> implementasi -> verifikasi hijau dengan mock fixtures. |
| **Performa & Benchmark** | `agency-performance-benchmarker` | `performance-profiling`, `diagnose-android-overheating` | Pantau komputasi kamera/TFLite di background Isolate; dilarang membuat klaim metrik fiktif tanpa benchmark riil. |
| **Dokumentasi & Platform** | `android-dev`, `kotlin-coroutines-expert` | `context7-mcp`, `context7-cli`, `find-docs` | Dokumentasi resmi dependency riil di `pubspec.yaml` dan bridging native CameraX non-blocking. |
| **Supabase Backend & Security** | `agency-software-architect` | `supabase-postgres-best-practices`, `security-predeploy-gate` | Wajib patuhi panduan di [.agents/rules/supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md). Clean Architecture Data Layer, PostgreSQL RLS, Cloud-to-Local Ready, dan Dart 3 sealed class `SupabaseResult<T>`. |

---

## 5. Integritas Kontrak Model MotionGRU & Machine Learning

1. **Verifikasi Kontrak:**
   - Kontrak MotionGRU (ekstraksi 353 fitur spasial + 353 delta velocity = 706-D, 543 koordinat MediaPipe Holistic, Float16 tensor shape, urutan fitur, label BISINDO/SIBI, dan preprocessing) **wajib diverifikasi langsung dari berkas model dan kode training asli**.
   - **Catat setiap ketidaksesuaian spesifikasi yang ditemukan; jangan memperbaikinya berdasarkan asumsi.**
2. **Larangan Klaim Metrik Tanpa Pengujian:**
   - Dilarang mengklaim akurasi ($\ge 92\%$), latency ($\le 45\text{ ms}$), FPS ($60\text{ FPS}$), atau kompatibilitas hardware tanpa hasil pengujian riil / benchmark pada target device.
3. **Larangan Membuat Skill MotionGRU Khusus:**
   - Dilarang membuat skill custom MotionGRU pada tahap ini sebelum kontrak model dan kode training diverifikasi secara definitif.

---

## 6. Standar Wajib Pengembangan & Keamanan Supabase (Best Practices)

Setiap agen yang membuat atau memodifikasi fitur yang bersangkutan dengan Supabase **wajib mengikuti aturan baku ini**:

1. **Pemanggilan Skill Terkurasi:**
   - PostgreSQL Schema, Migrasi SQL, RLS, & Indexing: Wajib gunakan `supabase-postgres-best-practices`.
   - Audit Keamanan Pra-Rilis: Wajib gunakan `security-predeploy-gate`.
2. **Arsitektur Kode di Flutter (Clean Architecture + GetX):**
   - Layanan Supabase (`SupabaseClient`, `SupabaseStorageClient`, `RealtimeChannel`) **HANYA boleh berada di Data Layer** (`lib/features/<feature>/services/` atau `lib/features/<feature>/data/datasources/`). Dilarang mengimpor `supabase_flutter` di widget/view atau domain entity.
   - Gunakan **Dart 3 `sealed class`** (`SupabaseResult<T>`, `SupabaseSuccess<T>`, `SupabaseFailure<T>`) untuk pemodelan hasil Supabase dan tangani dengan exhaustive `switch`.
   - Terapkan **defensive initialization (lazy null-safe getter `SupabaseClient? get _supabase`)** pada service Supabase agar unit test & widget test dapat berjalan tanpa crash ketika `Supabase.initialize()` belum dipanggil.
3. **Keamanan Mutlak (Row Level Security & Cloud-to-Local Ready):**
   - Setiap tabel PostgreSQL wajib mengaktifkan `ENABLE ROW LEVEL SECURITY` dan `CHECK` constraints ketat.
   - Konfigurasi URL wajib terpusat di `AppConstants.supabaseUrl` agar dapat dipindahkan dari Supabase Cloud ke Self-Hosted Supabase Docker di Mini PC Lokal hanya dengan mengubah 1 baris.
4. **Aturan Lengkap:** Baca panduan terperinci di [.agents/rules/supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md) dan [SUPABASE_ARCHITECTURE.md](file:///c:/fadli/project/sign2speech/SUPABASE_ARCHITECTURE.md).
