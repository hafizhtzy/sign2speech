# 🛡️ Konstitusi & Aturan Utama Proyek: Sign2Speech (Project Master Rules)

Dokumen ini adalah **Aturan Mutlak Tingkat Tertinggi (Hard Gate & Single Source of Truth Rules)** bagi seluruh agen AI (Antigravity, Claude, Cursor, Codex, maupun subagen) yang bekerja pada proyek **Sign2Speech (`speech2sign`)**.

Seluruh agen dan subagen **WAJIB** mematuhi **4 Pilar Utama**:
1. **Pilar 1:** Gerbang Wajib Pemanggilan Skill Sebelum Eksekusi (*Mandatory Pre-Action Skill Gate*)
2. **Pilar 2:** Batasan Rekayasa, Write-Through Registry & Anti-Overengineering (*Engineering Harness*)
3. **Pilar 3:** Kontrak Design System Sign2Speech, Responsivitas & Anti-AI-Slop (*UI/UX Standards*)
4. **Pilar 4:** Mode Mentor & Penjelasan Bahasa Awam (*Mandatory Mentor Mode & Explain-As-You-Code*)

---

## PILAR 1: GERBANG WAJIB SEBELUM NGODING, MENGUBAH, MENAMBAH FITUR, ATAU AUDIT KODE (MANDATORY SKILL GATE)

### 1.1 Hukum Utama: Dilarang Ngoding Sebelum Membaca Skill & Rules
> **ATURAN KERAS (ZERO-TOLERANCE GATE):**
> Agen AI **DILARANG KERAS** menulis kode baru (`write_file`), mengedit kode (`edit_file`), merombak arsitektur, memperbaiki bug, menambahkan fitur, atau melakukan audit kode **SEBELUM** terlebih dahulu:
> 1. **Mengidentifikasi domain fitur/tugas** yang diminta pengguna.
> 2. **Membaca (`read_file`) berkas `SKILL.md` yang relevan** dari daftar `.agents/skills/` proyek.
> 3. **Membaca (`read_file`) berkas aturan ini (`.agents/rules/project-master-rules.md`)** serta berkas pendukung (`DESIGN.md` / `SUPABASE_ARCHITECTURE.md`).
> 4. **Membaca (`read_file`) katalog `.agents/CODEBASE-REGISTRY.md`** untuk mengecek komponen, helper, dan service yang sudah tersedia sebelum membuat baru.
> 5. **Menerapkan checklist dan batasan dari skill & rules tersebut** secara ketat selama pengerjaan.

### 1.2 Alur Kerja Wajib 4-Tahap (Mandatory 4-Step Pre-Coding Workflow)
Setiap kali menerima instruksi koding, agen **WAJIB** menjalankan urutan ini:

1. **Tahap 1 — Klasifikasi Domain Tugas:**
   Tentukan domain tugas (misal: *UI Kasir + Supabase POS*, *MediaPipe CameraX + TFLite BISINDO*, atau *FIFO TTS + STT*).
2. **Tahap 2 — Panggil & Baca Skill (`read_file`) + Baca `.agents/CODEBASE-REGISTRY.md` (Hemat Token):**
   - Buka `SKILL.md` yang sesuai dengan matriks pada **Bagian 1.3**.
   - Buka dan baca `.agents/CODEBASE-REGISTRY.md` untuk mengetahui apakah widget UI, formatter, validator, atau service yang dibutuhkan sudah ada di `lib/core` atau `lib/features`. **Dilarang scan buta ke puluhan file dart jika informasinya sudah tercatat di registry.**
3. **Tahap 3 — Eksekusi Sesuai Kontrak Arsitektur & Engineering Harness:**
   Terapkan perubahan kode dengan mematuhi **Pilar 2** (Keep Flutter + GetX, Clean Architecture, 500-LOC Gate) dan **Pilar 3** (Design System `AppColors` & `AppTypography`, Multi-Bahasa `.tr`).
4. **Tahap 4 — Sinkronisasi `CODEBASE-REGISTRY.md`, Verifikasi Wajib, & Penjelasan Mentor:**
   - **Write-Through Sync:** Jika ada penambahan, perubahan signature/parameter, atau penghapusan item di `/core`, `/common`, atau `Services`, agen **WAJIB langsung memperbarui baris tabel di `.agents/CODEBASE-REGISTRY.md` pada giliran yang sama**.
   - Jalankan verifikasi mandiri (`flutter analyze` = 0 issues, test = 100% lulus).
   - Tutup seluruh respons dengan blok **"🎓 Pojok Mentor"** sesuai **Pilar 4**.

### 1.3 Matriks Pemetaan Tugas Proyek Sign2Speech $\rightarrow$ Skill & Rules Wajib

| No | Domain / Fitur yang Dikerjakan | Skill Wajib Dibaca (`read_file` ke `SKILL.md`) | File Rules Wajib Terkait |
| :- | :--- | :--- | :--- |
| **1** | **Supabase, PostgreSQL, RLS, Storage Bucket (`menu-photos` / `sign-videos`)** | `supabase-postgres-best-practices`, `security-predeploy-gate` | [supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md), [SUPABASE_ARCHITECTURE.md](file:///c:/fadli/project/sign2speech/SUPABASE_ARCHITECTURE.md) |
| **2** | **UI/UX, Halaman Kasir, Komponen, Tema Warna, Dark Mode, Lokalisasi** | `ui-ux-pro-max`, `design-system`, `ui-states`, `agency-ui-designer` | [ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md), [DESIGN.md](file:///c:/fadli/project/sign2speech/DESIGN.md) |
| **3** | **Layout Responsif Multi-Device (HP, Tablet, Foldable) & Perbaikan Overflow** | `flutter-build-responsive-layout`, `flutter-fix-layout-issues` | [ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md) |
| **4** | **Arsitektur Fitur Baru, GetX Controller, Bindings, Clean Architecture** | `flutter-apply-architecture-best-practices`, `flutter-expert`, `agency-software-architect` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **5** | **Debugging Bug, Layar Error/Putih, Race Condition, Crash Runtime** | `systematic-debugging`, `dart-fix-runtime-errors` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **6** | **Kamera Native Android CameraX, MediaPipe Holistic, TFLite BISINDO** | `android-dev`, `kotlin-coroutines-expert`, `performance-profiling`, `diagnose-android-overheating`, `artemis` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **7** | **Voice AI, Speech-to-Text (STT `id-ID`), Text-to-Speech (FIFO TTS)** | `agency-voice-ai-integration-engineer`, `voice-ai-engine-development` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **8** | **Unit Test, Widget Test, E2E Android Test, Mock & TDD** | `test-driven-development`, `artemis`, `flutter-add-widget-test`, `dart-add-unit-test`, `verification-before-completion` | [sign2speech-agent-guidelines.md](file:///c:/fadli/project/sign2speech/.agents/rules/sign2speech-agent-guidelines.md) |
| **9** | **Audit Kode, Audit Keamanan, Audit Aksesibilitas WCAG** | `agency-code-reviewer`, `code-review-checklist`, `security-predeploy-gate`, `accessibility-compliance-accessibility-audit` | [ui_development_rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/ui_development_rules.md), [supabase-development-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/supabase-development-rules.md) |
| **10** | **Perencanaan Fitur Baru, Brainstorming, Copywriting UI & PRD** | `brainstorming`, `writing-plans`, `humanizer`, `skill-advisor`, `project-rules-gate` | [project-master-rules.md](file:///c:/fadli/project/sign2speech/.agents/rules/project-master-rules.md) |

---

## PILAR 2: BATASAN REKAYASA, REGISTRY & ANTI-OVERENGINEERING (ENGINEERING HARNESS)

### 2.1 Wajib Gunakan Library yang Ada di Repo (Dependency Lock)
1. **Gunakan Hanya Package di `pubspec.yaml`:**
   - Proyek Sign2Speech telah memiliki dependensi matang (Flutter 3.47.x, Dart 3.13.x, GetX, Supabase Flutter, Google Fonts, TFLite, dll.).
2. **Dilarang Menambah Package Baru Tanpa Izin:**
   - **DILARANG KERAS** menjalankan `flutter pub add` atau mengedit `pubspec.yaml` untuk menambah library baru tanpa persetujuan eksplisit pengguna.
3. **Dilarang Mengganti State Management Sepihak:**
   - Proyek resmi menggunakan **Flutter + GetX** (`GetxController`, `Bindings`, `Obx`). Dilarang mengganti ke BLoC, Riverpod, atau Provider.

### 2.2 Arsitektur `/core` vs `/common` & Katalog Wajib `.agents/CODEBASE-REGISTRY.md`
1. **Pembagian Bersih:**
   - **`/core`:** Khusus pondasi & konfigurasi aplikasi (`AppColors`, `AppTypography`, `AppTheme`, `AppStrings`, `AppTranslations`, `SupabaseResult<T>`, `AppRoutes`, `AppAssets`, `AppCurrencyFormatter`, `AppPrimaryButton`, `AppCard`, `AppSnackbar`, `EmptyStateView`, `ResponsiveContentWrapper`).
   - **`Services`:** Khusus layanan bisnis & data (`SupabaseCafePosService`, `CafeMenuStorageService`, `BisindoClassifierService`, `BisindoTtsService`, `CameraFeedService`, `SpeechService`).
2. **Aturan Baca Dulu (Hemat Token):**
   - Sebelum membuat tombol, widget kartu, dialog, snackbar, formatter Rupiah, atau service baru, agen **WAJIB membaca `.agents/CODEBASE-REGISTRY.md`**. Jika sudah tercatat di tabel, langsung import dan gunakan.
3. **Aturan Catat Langsung (Write-Through Sync):**
   - Setiap kali agen membuat baru, mengubah parameter, atau menghapus item di `/core`, `/common`, atau `Services`, agen **WAJIB langsung memperbarui tabel 1-baris di `.agents/CODEBASE-REGISTRY.md` pada giliran yang sama**.

### 2.3 Anti-Overengineering & Anti-Halusinasi API
1. **Clean Architecture 3-Lapisan Tetap Ditegakkan:**
   - *Presentation Layer:* View dan GetxController. Tidak boleh ada `BuildContext` di dalam Controller atau Domain/Data layer.
   - *Domain Layer:* Entitas murni dan interface repository tanpa dependensi GetX/UI.
   - *Data Layer:* Implementasi data source, Supabase, dan native channels.
2. **Dilarang Abstraksi Baru yang Belum Perlu:**
   - Jangan membuat wrapper class atau interface bertumpuk jika pola yang ada (`SupabaseResult<T>`, `BaseRepository`) sudah mencukupi.
3. **Zero Hallucination:**
   - Dilarang mengarang method GetX atau Supabase yang tidak ada di versi `pubspec.lock`.

### 2.4 Aturan 500-LOC Confirmation Gate (Batas Baris Kode per File)
1. **Target Modularitas:**
   - Usahakan file controller, view, dan service tetap ramping di kisaran **$\le 300 - 450$ baris**.
2. **Gerbang Konfirmasi Wajib pada 500 Baris (500-LOC Gate):**
   - Apabila sebuah file yang sedang dibuat atau diedit **sudah melebihi atau akan melebihi $\pm 500$ baris kode (LOC)**:
   - Agen **DILARANG** langsung memecah file secara sepihak dan **DILARANG** terus menumpuk kode secara diam-diam.
   - Agen **WAJIB meminta konfirmasi terlebih dahulu kepada pengguna**:
     > *"File `[nama_file]` saat ini sudah/akan mencapai lebih dari 500 baris karena logic/halaman ini cukup panjang. Apakah tidak apa-apa saya lanjutkan lebih dari 500 baris di dalam file ini, atau Anda ingin saya pecah menjadi sub-komponen/file terpisah?"*

---

## PILAR 3: KONTRAK DESIGN SYSTEM SIGN2SPEECH, RESPONSIVITAS & ANTI-AI-SLOP

### 3.1 Single Source of Truth Warna & Tipografi (Zero Hardcoded Styles)
1. **Palet Warna Terpadu (`AppColors`):**
   - **Light Mode ("Cafe Warm Oat Milk / Espresso"):** `AppColors.canvas` (`#FDFBF7`), `AppColors.primary` (`#2C1E18`), `AppColors.secondary` (`#8C5A3C`), `AppColors.surface` (`#FFFFFF`), `AppColors.bgSurface` (`#F4EFE6`), `AppColors.border` (`#E6DCD2`), `AppColors.ink` (`#2C1E18`), `AppColors.muted` (`#6E5A4F`), `AppColors.matcha` (`#4A6B53`), `AppColors.amber` (`#D97724`), `AppColors.cameraDark` (`#191210`).
   - **Dark Mode ("Instagram AMOLED Minimalist"):** `AppColors.darkCanvas` (`#000000`), `AppColors.darkSurface` (`#121212`), `AppColors.darkBgSurface` (`#1E1E1E`), `AppColors.darkBorder` (`#262626`), `AppColors.darkPrimary` / `darkInk` (`#F5F5F5`), `AppColors.darkSecondary` (`#D49B78`), `AppColors.darkMuted` (`#A8A8A8`).
   - **DILARANG KERAS RAW HEX / COLOR:** Dilarang menggunakan `Color(0xFF...)` atau `Colors.red/blue`. Seluruh warna wajib memanggil `AppColors.<token>` dinamis.
2. **Tipografi Dinamis (`AppTypography`):**
   - Seluruh teks wajib menggunakan Google Fonts **Plus Jakarta Sans** melalui `AppTypography` (`display`, `headline`, `title`, `body`, `label`). Modifikasi hanya via `.copyWith()`. Dilarang menulis raw `TextStyle(...)`.

### 3.2 Multi-Bahasa Dinamis (Mandatory Dynamic Localization)
1. **Dilarang Hardcode String UI:**
   - Dilarang menulis teks statis (misal `Text('Simpan')` atau `Text('Menu Kopi')`) langsung di widget.
2. **Single Source of Truth Teks:**
   - Seluruh kunci teks wajib didaftarkan di `AppStrings` dan diterjemahkan dalam dua bahasa di `AppTranslations` (`id_ID` & `en_US`).
3. **Penggunaan Reaktif di Widget:**
   - Gunakan getter `.tr` reaktif di dalam `Obx(() => Text(AppStrings.startNow.tr))` agar UI langsung berganti bahasa tanpa restart aplikasi saat diubah di Pengaturan.

### 3.3 Aturan Wajib Responsif Multi-Device & Bebas RenderFlex Overflow
1. **Standar Window Breakpoint (Material 3 & Flutter Official):**
   - **Compact (`< 600 dp`):** Smartphone portrait. Single column, bottom sheet, padding horizontal 16-20 dp.
   - **Medium (`600 - 839 dp`):** Tablet portrait & foldable. 2 kolom grid/split view, navigation rail, padding horizontal 24-32 dp.
   - **Expanded (`≥ 840 dp`):** Tablet landscape & desktop. Master-detail split view, multi-column grid, dialog/card terpusat.
   - Gunakan helper `context.isCompact`, `context.isMedium`, `context.isExpanded`, `context.isLargeScreen` dari `responsive_layout.dart`.
2. **Batasan Lebar Maksimal (`ResponsiveContentWrapper`):**
   - Gunakan `ResponsiveBreakpoints.maxFormWidth` (580 dp) untuk form/onboarding, `maxContentWidth` (960 dp) untuk detail/settings, dan `maxDashboardWidth` (1140 dp) untuk dashboard/grid.
3. **Defensive Anti-Overflow:**
   - Setiap konten vertikal yang berpotensi meluap wajib dibungkus `SingleChildScrollView(physics: const BouncingScrollPhysics())`.
   - Setiap `Text` dinamis di dalam `Row` wajib dibungkus `Expanded` atau `Flexible` serta dilengkapi `overflow: TextOverflow.ellipsis` dan `maxLines`.
4. **Touch Targets:**
   - Seluruh elemen interaktif (`AppPrimaryButton`, `IconButton`, `InkWell`) wajib memiliki area sentuh minimal **$\ge 48\times 48\text{ dp}$**.
5. **Kelengkapan 6 State UI:**
   - Wajib menangani *Loading Skeleton/Spinner, Empty State (`EmptyStateView`), Error State (+ Retry), Normal/Success State, Offline Indicator (`AppColors.matcha`),* dan *Long Content State*.

---

## PILAR 4: MODE MENTOR & PENJELASAN BAHASA AWAM (MENTOR & EXPLAIN-AS-YOU-CODE)

### 4.1 Kewajiban Blok "🎓 Pojok Mentor" di Akhir Setiap Respons Koding/Perubahan
Setiap kali agen selesai menulis, mengubah, memperbaiki bug, atau merancang kode di proyek Sign2Speech, agen **WAJIB** menyertakan bagian penutup:

```markdown
---
### 🎓 Pojok Mentor: Kenapa Solusi Ini Dipilih?

1. **Analogi Sederhana (Bahasa Awam):**
   [Jelaskan konsep teknis atau perubahan yang baru dibuat menggunakan perumpamaan sehari-hari yang mudah dibayangkan oleh orang awam tanpa jargon rumit.]

2. **Bagaimana Kode Ini Bekerja (Step-by-Step):**
   - **Langkah 1:** [Jelaskan file/widget mana yang menerima input atau pemicu awal]
   - **Langkah 2:** [Jelaskan bagaimana controller/service memproses datanya]
   - **Langkah 3:** [Jelaskan hasil akhirnya di layar pengguna atau database]

3. **Kenapa Pakai Cara Ini? (Alasan Teknis & Trade-off):**
   - **Alasan Pemilihan:** [Jelaskan secara jujur kenapa solusi ini terbaik untuk Sign2Speech—misalnya karena me-reuse AppCard di /core/widgets, menjaga FPS 60fps kamera, atau hemat query Supabase.]
   - **Kenapa Tidak Pakai Cara Lain:** [Sebutkan singkat 1 alternatif lain dan kenapa kita menghindarinya—misalnya karena over-engineering, boros memori, atau melanggar RLS.]
```
