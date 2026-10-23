# Panduan & Aturan Agent: Proyek Flutter Sign2Speech

Dokumen ini adalah aturan resmi tingkat proyek (*Project Rule*) untuk Google Antigravity dan agen AI dalam pengembangan aplikasi **Sign2Speech**. Aturan ini wajib dipatuhi oleh seluruh agen dan subagen selama mengerjakan proyek.

---

## 1. Acuan Visual & Design System

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
     - **Dilarang Keras Menulis Raw Hex / Color:** Seluruh warna di widget wajib menggunakan `AppColors`.
   - **Tipografi Dinamis ([AppTypography](file:///c:/fadli/project/sign2speech/lib/core/theme/app_typography.dart)):** 
     - Google Fonts Plus Jakarta Sans untuk seluruh peran teks (Display, Headline, Title, Body, Label). Dilarang membuat `TextStyle(...)` tanpa melalui `AppTypography`.
   - **Multi-Bahasa Dinamis (Mandatory Dynamic Localization):**
     - Dilarang hardcode string teks antarmuka di widget! Seluruh teks antarmuka wajib didaftarkan di [AppStrings](file:///c:/fadli/project/sign2speech/lib/core/localization/app_strings.dart) dan diterjemahkan dalam dua bahasa di [AppTranslations](file:///c:/fadli/project/sign2speech/lib/core/localization/app_translations.dart) (`id_ID` & `en_US`).
     - Gunakan getter `.tr` reaktif di dalam `Obx(() => ...)` agar UI langsung berganti bahasa tanpa restart aplikasi saat diubah di Pengaturan.
   - **Aturan Lengkap:** Wajib patuhi panduan terstruktur di [.agents/rules/ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md).
   - **Ilustrasi Karakter:** Karakter editorial 2D dengan garis Espresso (`#2C1E18`) dan fill putih hangat.
2. **Integritas Desain Layar & Responsif:**
   - Pertahankan desain alur 12 layar yang telah disetujui.
   - Setiap layar scrollable wajib menggunakan `SingleChildScrollView(physics: BouncingScrollPhysics())` untuk mencegah *RenderFlex overflow*.
   - Seluruh elemen interaktif wajib memenuhi standar touch target minimum **$\ge 48$ dp**.

---

## 2. Arsitektur Kode & State Management

1. **State Management & DI:**
   - Proyek ini secara resmi menggunakan **Flutter + GetX** (`GetxController`, `Bindings`, `GetView`/`GetWidget`).
   - **Dilarang keras mengganti state management secara sepihak** (misalnya memaksakan migrasi ke BLoC, Riverpod, atau Provider) meskipun ada skill umum yang merekomendasikan hal tersebut.
2. **Clean Architecture 3-Lapisan:**
   - **Presentation Layer (`ui/` atau `presentation/`):** View dan GetxController. Tidak boleh ada dependensi `BuildContext` di luar widget tree atau di dalam domain/data layer.
   - **Domain Layer (`domain/`):** Entitas murni dan interface repository tanpa dependensi framework UI.
   - **Data Layer (`data/`):** Implementasi repository, data source (MediaPipe native event channel, TFLite Flutter, FIFO TTS queue, STT, tiered video cache).
3. **Versi Dependensi:**
   - Gunakan selalu dokumentasi yang sesuai dengan versi dependensi riil di [pubspec.yaml](file:///c:/speech2sign/pubspec.yaml) dan [pubspec.lock](file:///c:/speech2sign/pubspec.lock) (Flutter 3.47.x, Dart 3.13.x).

---

## 3. Pembagian Peran & Pemanggilan Skill

Muat persona agent atau skill secara spesifik sesuai tugas (*progressive disclosure*), jangan memuat seluruh katalog sekaligus:

| Kategori Tugas | The Agency Agent (Persona) | Agentic Awesome Skill (Prosedur) | Panduan Penggunaan |
| :--- | :--- | :--- | :--- |
| **Arsitektur Sistem** | `agency-software-architect` | `flutter-apply-architecture-best-practices` | Kawal pemisahan Presentation, Domain, Data. Domain murni bebas GetX/UI; Controller bebas BuildContext. |
| **Implementasi Flutter & Mobile** | `agency-mobile-app-builder` | `flutter-expert`, `mobile-developer`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues` | Implementasi widget GetX, layout responsif, touch target >= 48 dp, dan bridging CameraX EventChannel. |
| **Integrasi Voice AI (STT/TTS)** | `agency-voice-ai-integration-engineer` | `voice-ai-engine-development` | Kelola STT `id-ID`, antrean serial FIFO TTS, buffer ejaan alfabet 1500ms. Dilarang switch ke cloud/Whisper tanpa izin. |
| **Desain UI/UX & Visual** | `agency-ui-designer`, `agency-ux-architect` | `ui-ux-pro-max`, `design-system` | Acuan mutlak `DESIGN.md` (Cafe Warm Oat Milk / Espresso), font Plus Jakarta Sans, dan aset `assets/komponen_img/`. |
| **Aksesibilitas Universal** | `agency-accessibility-auditor` | `screen-reader-testing`, `accessibility-compliance-accessibility-audit` | Evaluasi kontras WCAG, touch target minimum 48 dp, dan uji screen reader. |
| **Code Review & Mutu Kode** | `agency-code-reviewer` | `code-review-checklist`, `code-review-excellence`, `requesting-code-review` | Periksa disposal controller/stream di `onClose()`, race condition token `_playSessionId`, dan sanitasi numerik. |
| **Testing & Otomasi QA** | `agency-test-automation-engineer` | `test-driven-development`, `flutter-add-widget-test`, `verification-before-completion` | Jalankan alur TDD, tulis tes gagal -> implementasi -> verifikasi hijau dengan mock fixtures. |
| **Performa & Benchmark** | `agency-performance-benchmarker` | `performance-profiling`, `diagnose-android-overheating` | Pantau komputasi kamera/TFLite di background Isolate; dilarang membuat klaim metrik fiktif tanpa benchmark riil. |
| **Dokumentasi & Platform** | `android-dev`, `kotlin-coroutines-expert` | `context7-mcp`, `context7-cli`, `find-docs` | Dokumentasi resmi dependency riil di `pubspec.yaml` dan bridging native CameraX non-blocking. |

---

## 4. Integritas Kontrak Model MotionGRU & Machine Learning

1. **Verifikasi Kontrak:**
   - Kontrak MotionGRU (ekstraksi 353 fitur spasial + 353 delta velocity = 706-D, 543 koordinat MediaPipe Holistic, Float16 tensor shape, urutan fitur, label BISINDO/SIBI, dan preprocessing) **wajib diverifikasi langsung dari berkas model dan kode training asli**.
   - **Catat setiap ketidaksesuaian spesifikasi yang ditemukan; jangan memperbaikinya berdasarkan asumsi.**
2. **Larangan Klaim Metrik Tanpa Pengujian:**
   - Dilarang mengklaim akurasi ($\ge 92\%$), latency ($\le 45\text{ ms}$), FPS ($60\text{ FPS}$), atau kompatibilitas hardware tanpa hasil pengujian riil / benchmark pada target device.
3. **Larangan Membuat Skill MotionGRU Khusus:**
   - Dilarang membuat skill custom MotionGRU pada tahap ini sebelum kontrak model dan kode training diverifikasi secara definitif.
