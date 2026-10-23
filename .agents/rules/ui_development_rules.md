# Aturan Baku Pengembangan UI/UX Antigravity: Sign2Speech

Dokumen ini adalah aturan wajib (*Mandatory Standard Rules*) untuk seluruh agen AI (Antigravity & subagen) saat membuat, memodifikasi, atau merefaktor komponen, widget, dan halaman pada proyek **Sign2Speech**.

Setiap pembuatan file Dart di layer presentasi (`lib/presentation/` atau `lib/features/*/widgets/`) **WAJIB** mematuhi kelima pilar berikut:

---

## 1. Multi-Bahasa Dinamis (Mandatory Dynamic Localization)

1. **Dilarang Keras Hardcode String UI:**
   - Dilarang menulis teks statis Bahasa Indonesia atau Inggris langsung di dalam widget (misalnya `Text('Simpan')` atau `Text('Save')`).
2. **Single Source of Truth Kunci Teks:**
   - Setiap teks antarmuka yang terlihat oleh pengguna **wajib** didaftarkan di [AppStrings](file:///c:/fadli/project/sign2speech/lib/core/localization/app_strings.dart).
   - Terjemahan **wajib** disediakan dalam dua bahasa sekaligus di [AppTranslations](file:///c:/fadli/project/sign2speech/lib/core/localization/app_translations.dart):
     - `id_ID` (Bahasa Indonesia)
     - `en_US` (English)
3. **Penggunaan Reaktif di Widget:**
   - Gunakan getter `.tr` dari GetX, misalnya: `AppStrings.save.tr`.
   - Bungkus widget dengan `Obx(() => ...)` jika teks berada dalam hierarki yang perlu langsung bereaksi saat bahasa diubah di Pengaturan tanpa memerlukan restart aplikasi.

```dart
// CONTOH SALAH (Violates Rule):
Text('Mulai Sekarang')

// CONTOH BENAR (Compliant):
Obx(() => Text(AppStrings.startNow.tr))
```

---

## 2. Palet Warna Terpadu (Single Source of Truth Colors)

1. **Dilarang Menggunakan Hex/Color Sembarangan:**
   - Dilarang menulis `Color(0xFF...)` atau `Colors.red`, `Colors.blue` langsung di widget.
2. **Acuan Tunggal [AppColors](file:///c:/fadli/project/sign2speech/lib/core/theme/app_colors.dart):**
   - Gunakan palet resmi **"Cafe Warm Oat Milk / Espresso"**:
     - `AppColors.canvas` (`#FDFBF7`): Background utama aplikasi (Warm Oat Milk / Cream).
     - `AppColors.bgSurface` (`#F4EFE6`): Background kartu sekunder & chips (Latte Foam).
     - `AppColors.surface` (`#FFFFFF`): Kartu elevated putih bersih.
     - `AppColors.border` (`#E6DCD2`): Garis batas kartu dan input.
     - `AppColors.primary` (`#2C1E18`): Rich Espresso Brown untuk aksi utama & kartu Sign to Speech.
     - `AppColors.secondary` (`#8C5A3C`): Warm Caramel / Cinnamon untuk Speech to Sign & aksen aktif.
     - `AppColors.matcha` (`#4A6B53`): Matcha Sage untuk status sukses & indikator video offline.
     - `AppColors.amber` (`#D97724`): Amber Gold untuk warning & highlight.
     - `AppColors.cameraDark` (`#191210`): Espresso Dark untuk viewport kamera & viewfinder.
     - `AppColors.ink` (`#2C1E18`): Teks judul utama.
     - `AppColors.muted` (`#6E5A4F`): Teks deskripsi & subtitle.

```dart
// CONTOH SALAH:
Container(color: const Color(0xFF1B3B4B))

// CONTOH BENAR:
Container(color: AppColors.primary)
```

---

## 3. Tipografi Dinamis (Dynamic Typography)

1. **Dilarang Raw TextStyle:**
   - Dilarang membuat `TextStyle(fontSize: 16, fontWeight: FontWeight.bold)` sembarangan.
2. **Acuan Tunggal [AppTypography](file:///c:/fadli/project/sign2speech/lib/core/theme/app_typography.dart):**
   - Seluruh teks wajib menggunakan Google Fonts **Plus Jakarta Sans** melalui hierarki `AppTypography`:
     - Display: `AppTypography.displayLarge`, `displayMedium`, `displaySmall`
     - Headline: `AppTypography.headlineLarge`, `headlineMedium`, `headlineSmall`
     - Title: `AppTypography.titleLarge`, `titleMedium`, `titleSmall`
     - Body: `AppTypography.bodyLarge`, `bodyMedium`, `bodySmall`
     - Label: `AppTypography.labelLarge`, `labelMedium`, `labelSmall`
   - Modifikasi hanya boleh dilakukan melalui `.copyWith(...)` (misalnya untuk warna atau weight spesifik).

```dart
// CONTOH SALAH:
Text('Title', style: TextStyle(fontSize: 18, color: Colors.black))

// CONTOH BENAR:
Text('Title', style: AppTypography.titleMedium.copyWith(color: AppColors.ink))
```

---

## 4. Layout Responsif & Bebas RenderFlex Overflow

1. **Proteksi Layar Kecil:**
   - Setiap halaman yang berisi formulir, tombol panjang, atau konten vertikal wajib dibungkus dengan:
     ```dart
     SingleChildScrollView(
       physics: const BouncingScrollPhysics(),
       child: ...
     )
     ```
   - Hindari penggunaan `Spacer()` di dalam `Column` tanpa pembatas ketinggian.
2. **Teks Dinamis Fleksibel:**
   - Gunakan `Flexible` atau `Expanded` di dalam `Row` saat teks berpotensi panjang agar tidak overflow.
3. **Standar Aksesibilitas Touch Target:**
   - Semua elemen yang dapat diklik (`AppPrimaryButton`, `IconButton`, `InkWell`, chip) wajib memiliki touch target minimum **$\ge 48\times 48$ dp**.
4. **Proteksi Skala Font:**
   - Pertahankan clamping `MediaQuery.textScaler.clamp(maxScaleFactor: 1.25)` pada level root aplikasi.

---

## 5. Protokol Anti-Lag & Performa Tinggi (Mobile Entry-Spec Safe)

1. **Dilarang Reactive Churn di 60 FPS:**
   - Dilarang meng-update variabel GetX `.obs` pada setiap frame kamera (60 Hz). Gunakan throttling interval $\ge 65$ ms untuk progress UI dan $\ge 500$ ms untuk frame counter.
2. **Komputasi Berat Wajib di Background Isolate:**
   - Ekstraksi 353 fitur spasial + 353 kecepatan delta (706-D) dan interpolasi 33.888 float wajib dijalankan di Isolate via `Isolate.run` atau `compute` (contoh: `buildModelTensorAsync()`).
3. **Isolasi Raster dengan `RepaintBoundary`:**
   - Setiap komponen kamera (`CameraX PlatformView`, HUD overlay animasi, candidate loader) wajib dibungkus dengan `RepaintBoundary` untuk menjaga UI thread <16 ms per frame (60 FPS stabil).
