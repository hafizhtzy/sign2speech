# Sign2Speech — Sistem Komunikasi Dua Arah & POS Kafe Inklusif

Aplikasi Flutter **Sign2Speech** untuk menjembatani komunikasi dua arah antara **Teman Tuli** (pengguna bahasa isyarat BISINDO & SIBI) dan **Teman Dengar** (masyarakat umum, kasir kafe, petugas loket layanan publik, dan tenaga medis) secara *real-time*, alami, dan *offline-first*. Dilengkapi dengan sistem transaksi kafe inklusif **Three-Role System (`CUSTOMER`, `CASHIER`, `ADMIN`)**, self-order meja, Dual-View Meja Kasir & Barista AI, serta integrasi **Supabase PostgreSQL & Storage**.

---

## ⚡ Panduan Cepat Menjalankan Aplikasi (Quick Start)

Apakah setelah `git clone` aplikasi langsung bisa dijalankan? **YA, LANGSUNG BISA!**

Proyek ini sudah dikonfigurasi secara *defensive* dan memiliki *default connection* ke Supabase Development Cloud, serta model AI MediaPipe yang berjalan 100% *on-device* (offline).

### Langkah 1: Clone Repository
```bash
git clone <URL_REPOSITORY_ANDA>
cd sign2speech
```

### Langkah 2: Pasang Dependencies Flutter
Pastikan Flutter SDK (>= 3.24.x) dan Dart (>= 3.5.x) sudah terpasang di komputer Anda.
```bash
flutter pub get
```

### Langkah 3: Jalankan Aplikasi
Hubungkan perangkat Android fisik (dengan USB Debugging aktif) atau nyalakan Android Emulator, lalu jalankan:
```bash
flutter run
```

---

## 🗄️ Memahami Konsep Supabase pada Proyek Ini

Bagi Anda yang terbiasa dengan MySQL atau baru migrasi dari Firebase:

### 1. Apa itu Supabase?
Supabase adalah platform **Backend-as-a-Service (BaaS)** berbasis **PostgreSQL**. Berbeda dengan Firebase yang NoSQL (Firestore), Supabase adalah *relational database* (tabel, relasi foreign key, skema ketat) yang dilengkapi fitur modern:
- **Auth**: Autentikasi email, password, session JWT, dan PKCE flow.
- **Row Level Security (RLS)**: Proteksi data langsung di tingkat baris PostgreSQL (misal: Pelanggan hanya bisa membaca pesanannya sendiri, Kasir hanya bisa membaca transaksi aktif, Admin bisa mengelola seluruh data).
- **Storage Buckets**: Tempat menyimpan file media (foto menu kopi dan video bahasa isyarat).
- **Realtime WebSocket**: Sinkronisasi otomatis layar kasir dan layar pembeli secara instan.

### 2. Apakah Saat Clone Repo Otomatis Bikin Database Baru Sendiri?
> **Jawabannya: TIDAK OTOMATIS.**  
> Git **hanya mendownload kode Flutter dan berkas skrip migrasi SQL (`supabase/migrations/`)**. Git tidak bisa otomatis membuatkan server database di laptop Anda.

Ada **dua skenario** penggunaan database untuk tim pengembang:

#### Skenario A: Menggunakan Shared Database (Rekomendasi untuk Kolaborasi Tim)
Jika Anda dan rekan tim sedang mengembangkan atau menguji aplikasi bersama:
- Anda **tidak perlu membuat database baru**.
- Kode aplikasi di [AppConstants](lib/core/constants/app_constants.dart) sudah memiliki *default credentials* yang terhubung ke 1 proyek Supabase Cloud bersama.
- Ketika rekan Anda mendaftar akun pelanggan atau membuat pesanan, datanya akan masuk ke database cloud yang sama secara *real-time*.

#### Skenario B: Membuat Database Sendiri dari Nol (Fresh Independent Project)
Jika rekan Anda ingin memiliki database terpisah (misalnya untuk tugas mandiri, skripsi, atau hosting pribadi):
1. Buka [Supabase Dashboard](https://supabase.com) dan buat akun gratis.
2. Klik tombol **New Project**, beri nama (misal: `sign2speech-db`) dan atur kata sandi database Anda.
3. Setelah project selesai dibuat, buka menu **SQL Editor** di sidebar kiri.
4. Buka file [supabase/migrations/20261118000000_three_role_rbac_and_erp_schema.sql](supabase/migrations/20261118000000_three_role_rbac_and_erp_schema.sql), salin seluruh isinya, tempel ke dalam SQL Editor Supabase, lalu klik **Run**.
   - *Sekali klik, seluruh tabel (`profiles`, `cafe_menus`, `cafe_orders`, `qris_payments`, `audit_logs`, dll.), constraints, enum, dan RLS policies akan terbuat otomatis!*
5. Buka menu **Storage** di sidebar Supabase, buat dua bucket:
   - `menu-photos` (Atur sebagai **Public Bucket**)
   - `sign-videos` (Atur sebagai **Public Bucket**)
6. Hubungkan aplikasi ke proyek Supabase baru Anda:
   - Salin file `.env.example` menjadi `.env`:
     ```bash
     cp .env.example .env
     ```
   - Masukkan **Project URL** dan **anon public key** dari menu *Project Settings -> API* di Supabase ke dalam `.env`:
     ```env
     SUPABASE_URL=https://proyek-anda.supabase.co
     SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsIn...
     MENU_PHOTOS_BUCKET=menu-photos
     SIGN_VIDEOS_BUCKET=sign-videos
     ```
   - Jalankan Flutter dengan menyertakan file `.env`:
     ```bash
     flutter run --dart-define-from-file=.env
     ```

---

## 👥 Sistem Tiga Role (Customer, Cashier, Admin)

Aplikasi menerapkan sistem otorisasi **Least Privilege** dengan 3 peran berbeda:

| Role | Cara Pembuatan Akun | Fitur & Akses Utama |
| :--- | :--- | :--- |
| **CUSTOMER** *(Pelanggan)* | Registrasi mandiri di aplikasi (*Daftar Akun*) | - Memesan kopi langsung dari tempat duduk (pilih nomor meja)<br>- Melakukan Checkout & Bayar QRIS<br>- Mode Pairing jika memesan langsung di tablet meja kasir<br>- Mengakses Sign-to-Speech & Speech-to-Sign |
| **CASHIER** *(Kasir)* | Dibuat oleh Admin Kafe via dashboard | - Akses Meja Kasir & Barista AI (`/cafe-cashier-counter`)<br>- Memproses antrean pesanan & panggil pesanan (Suara TTS / Getar Teman Tuli)<br>- Memutar layar 180° menghadap pembeli (*Single Tablet Switch*)<br>- Mode 2 Tablet Sinkron Ruang via kode ruangan |
| **ADMIN** *(Pemilik / Manajer)* | Provisioning aman oleh pemilik sistem | - Akses Dashboard Admin Sign2Speech (`/admin-dashboard`)<br>- CRUD Katalog Menu & Upload Foto ke Supabase Storage<br>- Manajemen Stok & Initial Stock Opname<br>- Monitoring Transaksi & Pembayaran QRIS<br>- Manajemen Akun Kasir (Aktifkan / Nonaktifkan Staf)<br>- Laporan Penjualan & Audit Log |

### Cara Membuat Akun Admin Pertama (First Admin Provisioning)
Demi keamanan perbankan dan data kafe, **tidak ada tombol daftar publik untuk Admin**. Untuk membuat akun Admin pertama pada database baru:
1. Daftarkan akun baru di halaman registrasi aplikasi dengan email Anda (misal: `admin@kafe.com`).
2. Buka **SQL Editor** di dashboard Supabase Anda, lalu jalankan perintah berikut:
   ```sql
   UPDATE public.profiles
   SET role = 'ADMIN', status = 'active'
   WHERE email = 'admin@kafe.com';
   ```
3. Login kembali di aplikasi dengan email tersebut. Anda akan langsung diarahkan ke **Dashboard Admin Sign2Speech**.

---

## 📱 Arsitektur & Teknologi

- **Framework**: Flutter (Dart 3.x, Flutter 3.24+)
- **State Management & Dependency Injection**: **GetX** (`GetxController`, `Bindings`, `GetMaterialApp`)
- **Pola Arsitektur**: Clean Architecture 3-Lapisan:
  - **Presentation Layer** (`lib/presentation/`, `lib/core/widgets/`, `lib/features/*/screens/`): UI responsif multi-device (smartphone, tablet, desktop/foldable), bottom navigation shell, custom theme token.
  - **Domain Layer** (`lib/features/*/domain/models/`): Entitas murni (`UserProfile`, `AppUserRole`, `CoffeeMenuItem`, `CafeOrderTicket`, `QrisPaymentRecord`, `SignToken`, dll).
  - **Data Layer** (`lib/core/auth/services/`, `lib/features/*/data/`): Layanan Supabase PostgreSQL, Realtime Session Channel, Supabase Storage Client, dan TFLite Vision Pipeline.
- **Keamanan & Penyimpanan Sesi**: `flutter_secure_storage` untuk enkripsi token JWT dan PKCE code verifier di perangkat secara aman.
- **AI & Visi Komputer**: Ekstraksi landmark MediaPipe & klasifikasi MotionGRU berjalan 100% lokal (*on-device privacy*).

---

## 🎨 Tema & Sistem Desain (Cafe Warm Oat Milk / Espresso)

Sistem visual mengacu pada palet resmi di [AppColors](lib/core/theme/app_colors.dart):
- **Primary**: Rich Espresso Brown (`#2C1E18` / `AppColors.primary`)
- **Secondary**: Warm Caramel / Cinnamon (`#8C5A3C` / `AppColors.secondary`)
- **Canvas / Background**: Warm Oat Milk / Cream (`#FDFBF7` / `AppColors.canvas`)
- **Card / Surface**: Pure Warm White (`#FFFFFF` / `AppColors.surface`) & Latte Foam (`#F4EFE6` / `AppColors.bgSurface`)
- **Semantic Accents**: Matcha Sage (`#4A6B53` / `AppColors.matcha` untuk sukses & status online), Amber Gold (`#D97724` / `AppColors.amber` untuk peringatan).
- **Dark Mode**: Instagram AMOLED Minimalist True Black (`#000000` / `AppColors.darkCanvas`).
- **Tipografi**: Google Fonts **Plus Jakarta Sans** melalui [AppTypography](lib/core/theme/app_typography.dart).
- **Multi-Bahasa**: Multi-bahasa dinamis reaktif via [AppStrings](lib/core/localization/app_strings.dart) & [AppTranslations](lib/core/localization/app_translations.dart) (`id_ID` & `en_US`).

---

## 🧪 Verifikasi & Pengujian

Aplikasi dilengkapi dengan rangkaian unit dan widget test yang komprehensif:

### Menjalankan Static Analysis (Zero Issues Gate)
```bash
dart analyze
```

### Menjalankan Seluruh Unit & Widget Tests
```bash
flutter test
```

### Menjalankan Uji Spesifik Role & Pemesanan
```bash
flutter test test/features/customer/customer_order_and_qris_test.dart
flutter test test/presentation/screens/settings_screen_test.dart
flutter test test/core/widgets/cashier_fab_test.dart
```

### Membangun APK Rilis untuk Android
```bash
flutter build apk --release
```
Hasil file APK rilis berada di:
`build/app/outputs/flutter-apk/app-release.apk`
