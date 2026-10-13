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

Muat skill secara spesifik sesuai tugas (*progressive disclosure*), jangan memuat seluruh katalog sekaligus:

| Kategori Tugas | Skill yang Digunakan | Panduan Penggunaan |
| :--- | :--- | :--- |
| **Desain UI/UX & Konsistensi Visual** | `ui-ux-pro-max`, `design-system`, `stitch-generate-design`, `stitch-manage-design-system` | Gunakan flag `--stack flutter` pada `ui-ux-pro-max/scripts/search.py`. Wajib selaraskan output dengan token di `DESIGN.md`. |
| **Implementasi Flutter & Dart** | `flutter-apply-architecture-best-practices`, `flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-implement-json-serialization`, `dart-*` | Terapkan pada pembuatan widget, binding, model data, dan isolasi isolate. Adaptasikan struktur MVVM/Clean Architecture ke GetX. |
| **Eksekusi Rencana, TDD, Debugging & Verifikasi** | `executing-plans`, `subagent-driven-development`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review` | Jalankan alur TDD (tulis tes gagal $\rightarrow$ implementasi $\rightarrow$ verifikasi hijau). Ikuti checklist rencana langkah demi langkah. |
| **Native Android (CameraX & MediaPipe)** | `android-dev`, `kotlin-coroutines-expert` | Terapkan pada bridging `EventChannel`, isolasi thread CameraX (`STRATEGY_KEEP_ONLY_LATEST`), dan sanitasi koordinat NaN/Infinity. |
| **Performa & Suhu Perangkat** | `diagnose-android-overheating` | Pantau komputasi kamera dan TFLite agar tidak memicu thermal throttling atau frame drop di Main UI Thread. |
| **State UI Tepi & Mode Offline** | `ui-states` | Pastikan seluruh state (loading, error, camera ready, light low, offline Tier 1-3, microphone permission) ter-handle sesuai PRD. |
| **Audit Aksesibilitas Universal** | `accessibility-compliance-accessibility-audit` | Evaluasi keterbacaan kontras, touch target minimum 48 dp, haptic feedback, dan kompatibilitas screen reader. |
| **Dokumentasi Library Eksternal** | `context7-mcp`, `context7-cli`, `find-docs` | Ambil dokumentasi library resmi versi terbaru untuk dependensi Flutter/Dart. |

---

## 4. Integritas Kontrak Model MotionGRU & Machine Learning

1. **Verifikasi Kontrak:**
   - Kontrak MotionGRU (ekstraksi 353 fitur spasial + 353 delta velocity = 706-D, 543 koordinat MediaPipe Holistic, Float16 tensor shape, urutan fitur, label BISINDO/SIBI, dan preprocessing) **wajib diverifikasi langsung dari berkas model dan kode training asli**.
   - **Catat setiap ketidaksesuaian spesifikasi yang ditemukan; jangan memperbaikinya berdasarkan asumsi.**
2. **Larangan Klaim Metrik Tanpa Pengujian:**
   - Dilarang mengklaim akurasi ($\ge 92\%$), latency ($\le 45\text{ ms}$), FPS ($60\text{ FPS}$), atau kompatibilitas hardware tanpa hasil pengujian riil / benchmark pada target device.
3. **Larangan Membuat Skill MotionGRU Khusus:**
   - Dilarang membuat skill custom MotionGRU pada tahap ini sebelum kontrak model dan kode training diverifikasi secara definitif.
