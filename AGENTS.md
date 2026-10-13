# Panduan & Aturan Agent: Proyek Flutter Sign2Speech

Dokumen ini adalah aturan resmi tingkat proyek (*Project Rule*) untuk Google Antigravity dan agen AI dalam pengembangan aplikasi **Sign2Speech**. Aturan ini wajib dipatuhi oleh seluruh agen dan subagen selama mengerjakan proyek.

---

## 1. Acuan Visual & Design System

1. **Sumber Kebenaran Visual:**
   - [DESIGN.md](file:///c:/speech2sign/DESIGN.md) adalah satu-satunya acuan desain visual utama aplikasi.
   - **Palet Warna "Nordic Ocean Playful Editorial":**
     - Primary: Mineral Ocean Blue (`#1B3B4B`)
     - Secondary / Active: Fjord Blue (`#38687D`)
     - Canvas Background: Warm Alabaster (`#F9F9F7`)
     - Card / Surfaces: Pure White (`#FFFFFF`)
     - Chips / Badges: Pale Mist (`#EAF0F2`)
     - Ink / Linework: Deep Graphite (`#192328`) — hindari hitam murni (`#000000`)
     - Muted Text: Stone Slate (`#6B7B83`)
     - Borders: Structural Blue-Gray (`#D1DCE0`)
   - **Tipografi:** Plus Jakarta Sans untuk seluruh heading, body, label tombol, dan angka (jangan ganti dengan Inter atau Roboto default).
   - **Bahasa Copywriting UI:** Seluruh copy antarmuka menggunakan **Bahasa Indonesia** baku yang ramah, kecuali nama merek dan istilah teknis resmi (Sign2Speech, BISINDO, SIBI, Sign-to-Speech, Speech-to-Sign).
   - **Ilustrasi Karakter:** Karakter editorial 2D hitam-putih dengan garis Deep Graphite (`#192328`) dan fill putih hangat (karakter wanita muda berambut ikal cepol dan pria muda berambut pendek). Ilustrasi tangan bersifat kontekstual/edukatif, bukan representasi BISINDO/SIBI yang diverifikasi.
2. **Integritas Desain Layar:**
   - Pertahankan desain 12 layar yang telah disetujui dalam storyboard / rancangan desain. Dilarang merombak layout yang sudah disetujui tanpa instruksi eksplisit.

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
| **Desain UI/UX & Visual** | `agency-ui-designer`, `agency-ux-architect` | `ui-ux-pro-max`, `design-system` | Acuan mutlak `DESIGN.md` (Nordic Ocean), font Plus Jakarta Sans, dan aset `assets/komponen_img/`. |
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
