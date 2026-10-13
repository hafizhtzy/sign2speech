# Sign2Speech — Sistem Komunikasi Dua Arah Aksesibilitas Universal

Aplikasi Flutter **Sign2Speech** untuk menjembatani komunikasi dua arah antara **Teman Tuli** (pengguna bahasa isyarat BISINDO & SIBI) dan **Teman Dengar** (masyarakat umum, petugas loket layanan publik, dan tenaga medis) secara *real-time*, alami, dan *offline-first*.

---

## 1. Arsitektur & Teknologi

- **Framework**: Flutter (Dart 3.x, Flutter 3.47.x)
- **State Management & Dependency Injection**: **GetX** (`GetxController`, `Bindings`, `GetMaterialApp`)
- **Pola Arsitektur**: Clean Architecture 3-Lapisan:
  - **Presentation Layer** (`lib/presentation/`, `lib/core/widgets/`): 13 layar interaktif responsif, bottom navigation shell, GetX bindings, komponen UI mandiri.
  - **Domain Layer** (`lib/features/sign_language/models/`, `lib/features/history/models/`): Entitas murni (`LandmarkFrame`, `BisindoPrediction`, `SignToken`, `SignVideoEntry`, `SignSearchResult`, `SignLanguageCatalog`, `HistoryItem`).
  - **Data Layer** (`lib/features/sign_language/services/`, `lib/features/translator/services/`, `lib/features/history/services/`): Classifier TFLite MotionGRU, segmenter isyarat, FIFO TTS Indonesian queue, STT speech service, tiered video caching & repository.

---

## 2. Tema & Identitas Visual (Nordic Ocean Playful Editorial)

Sistem desain mengacu penuh pada `DESIGN.md` dan storyboard referensi 12 layar:
- **Primary**: Mineral Ocean Blue (`#1B3B4B`)
- **Secondary**: Fjord Blue (`#38687D`)
- **Canvas / Background**: Warm Alabaster (`#F9F9F7`)
- **Card / Surface**: Pure White (`#FFFFFF`)
- **Pale Mist**: Accent Container & Chips (`#EAF0F2`)
- **Soft Fjord**: Selected Tint (`#D7E3E8`)
- **Ink / Typography**: Deep Graphite (`#192328`)
- **Muted Text**: Stone Slate (`#6B7B83`)
- **Borders**: Structural Blue-Gray (`#D1DCE0`)
- **Tipografi**: **Plus Jakarta Sans** untuk seluruh UI.
- **Copywriting**: Bahasa Indonesia baku yang ramah dan inklusif.
- **Touch Target**: Seluruh tombol aksi berukuran minimum >= 48 x 48 dp.

---

## 3. Pemetaan Komponen Gambar (`assets/komponen_img/`)

Semua ilustrasi editorial 2D dipetakan secara terpisah sebagai widget Flutter interaktif (`AppAssets`):
| File Aset | Representasi Komponen | Pemakaian Layar |
| :--- | :--- | :--- |
| `...-1.png` | Wanita rambut cepol | Onboarding 1 (Jembatan Komunikasi) |
| `...-2.png` | Pria gestur tangan terbuka | Onboarding 2 (Semua Kesempatan) |
| `...-3.png` | Ilustrasi Teman Tuli | Layar 04 (Kartu Pilih Peran) |
| `...-4.png` | Ilustrasi Teman Dengar | Layar 04 (Kartu Pilih Peran) |
| `...-5.png` | Emblem Lambang BISINDO | Layar 05 (Pilih Bahasa Isyarat) |
| `...-6.png` | Emblem Lambang SIBI | Layar 05 (Pilih Bahasa Isyarat) |
| `...-7.png` | Logo Bulat Sign2Speech | Layar 01 (Splash) & Layar 06 (Beranda) |
| `...-8.png` | Lencana Audio Waveform | Mikrofon & Audio State |
| `...-9.png` | Banner Editorial Lebar | Layar 06 (Banner Selamat Datang Beranda) |
| `...-10.png` | Karakter Kartu Fitur | Empty State Riwayat & Perpustakaan |

---

## 4. Daftar 13 Layar & Alur Navigasi

1. **01 Splash Screen (`/`)**: Animasi logo, tagline *"Berkomunikasi Tanpa Batas"*, transisi otomatis berbasis `SharedPreferences`.
2. **02 Onboarding 1 (`/onboarding-1`)**: Penjelasan alur dua arah kamera -> suara dan suara -> video isyarat.
3. **03 Onboarding 2 (`/onboarding-2`)**: Skenario pelayanan publik, fasilitas kesehatan, dan privasi on-device.
4. **04 Pilih Peran (`/choose-role`)**: Pemilihan peran Teman Tuli atau Teman Dengar dengan kartu bertumpuk.
5. **05 Pilih Bahasa Isyarat (`/choose-language`)**: Pemilihan sistem isyarat BISINDO (47 kelas) atau SIBI (72 kelas).
6. **06 Beranda (`/main` tab 0)**: Header status, banner editorial, 2 kartu fitur utama (Sign to Speech & Speech to Sign), akses katalog cepat, dan riwayat terkini.
7. **07 Kamera Sign-to-Speech (`/sign-to-speech-camera`)**: Viewfinder HUD CameraX, pengalih model BISINDO/SIBI, cincin konfirmasi gestur *HoldConfirmRing*, kartu transkrip real-time, tombol Spasi & Reset, dan chip uji coba gestur langsung.
8. **08 Hasil Sign-to-Speech (`/sign-to-speech-result`)**: Teks terjemahan kontras tinggi, tombol dengarkan TTS suara id-ID, salin ke papan klip, dan simpan ke riwayat.
9. **09 Mikrofon Speech-to-Sign (`/speech-to-sign-mic`)**: Tombol mikrofon sentuh, visualisasi gelombang suara 5-batang responsif, transkrip parsial, dan chip uji coba ucapan instan.
10. **10 Hasil Speech-to-Sign (`/speech-to-sign-result`)**: Teks ucapan masukan, pemutar video isyarat berurutan (*SignVideoPlayer*), penanda kata aktif (*active word chips*), kontrol kecepatan (0.75x, 1.0x, 1.25x), dan indikator status tier offline.
11. **11 Perpustakaan Isyarat (`/main` tab 2)**: Pencarian kosakata instan, filter kategori (Salam, Keluarga, Kesehatan, Belanja, Darurat, Layanan Publik), serta unduhan paket kategori offline.
12. **12 Pengaturan (`/main` tab 3)**: Pengaturan bahasa isyarat, peran pengguna, kecepatan suara TTS, kecepatan video, pembersihan cache lokal, informasi privasi on-device, dan tombol reset onboarding.
13. **13 Riwayat Percakapan (`/main` tab 1)**: Filter percakapan (Semua, Sign to Speech, Speech to Sign), putar ulang audio/video, hapus entri perorangan, dan dialog konfirmasi hapus semua.

---

## 5. Cara Menjalankan & Menguji

### Menjalankan Static Analysis
```bash
flutter analyze
```
*(Hasil: No issues found!)*

### Menjalankan Unit, Widget, dan Integration Tests
```bash
flutter test
```
*(Hasil: 39/39 tests passed!)*

### Membangun Android Debug APK
```bash
cd android
./gradlew assembleDebug
```
*(Hasil: BUILD SUCCESSFUL)*

### Menjalankan di Perangkat / Emulator
```bash
flutter run
```
