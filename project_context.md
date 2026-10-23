# Project Context — Sign2Speech

> Ringkasan konteks untuk Google Antigravity dan coding agent yang melanjutkan proyek.
> Diperbarui: 13 Oktober 2026 (Asia/Jakarta).
> Status: spesifikasi dan arahan implementasi tersedia; hasil implementasi, test, build, dan integrasi perangkat belum diverifikasi dalam obrolan ini.

## 1. Tujuan dokumen dan sumber

Dokumen ini merangkum PRD, implementation plan, logic, desain, Project Rule, serta keputusan pengguna dalam obrolan. Dokumen ini tidak menggantikan sumber asli dan tidak menjadi bukti bahwa aplikasi telah selesai.

Sumber yang telah dibaca:
- `2026-10-13-sign-and-speech-prd(1).md`: PRD versi 2.1.0, Document ID `PRD-S2S-2026-001`, bertanda Approved / Ready for Engineering Execution.
- `2026-10-13-sign-and-speech-plan(1).md`: rencana implementasi sembilan task utama.
- `logic-sign(1).md`: pada lampiran yang dibaca berisi implementation plan dengan task serupa; jangan diasumsikan sebagai kontrak training yang independen.
- `DESIGN (1).md`: Cafe Warm Oat Milk / Espresso Playful Editorial, kontrak layar, aset, state, dan aksesibilitas.
- Project Rule Sign2Speech yang ditempel pengguna dalam obrolan.
- Screenshot explorer workspace `speech2sign` yang diberikan pengguna.

Di workspace pengguna, sumber tersedia dengan nama tanpa `(1)`, termasuk `DESIGN.md`, `logic-sign.md`, PRD, dan plan. Cari file yang benar-benar tersedia; akhiran salinan bukan nama wajib.

### Prioritas acuan

1. Instruksi eksplisit terbaru pengguna dan Project Rule.
2. `DESIGN.md` sebagai sumber visual utama; referensi layar untuk komposisi yang disetujui.
3. PRD untuk kebutuhan produk dan perilaku fitur.
4. Model, metadata, labels, dan kode training asli untuk kontrak ML.
5. Implementation plan untuk urutan pengerjaan dan checklist.
6. Dokumen ini sebagai ringkasan konteks.

Jika sumber bertentangan, catat konflik, tentukan bagian yang terdampak, dan lanjutkan bagian independen. Jangan menyelesaikan konflik ML dengan asumsi.

## 2. Produk dan cakupan

**Nama produk:** Sign2Speech.

**Tujuan:** membantu komunikasi dua arah antara Teman Tuli dan Teman Dengar dalam kehidupan sehari-hari, belanja, transportasi, layanan publik, dan fasilitas kesehatan.

**Platform:** Flutter, Android-first; struktur dapat diperluas ke iOS. Dukungan runtime native iOS belum terbukti.

**Dua alur inti:**
- Sign-to-Speech: kamera → landmark → ekstraksi fitur temporal → MotionGRU/TFLite → transkrip → TTS Bahasa Indonesia.
- Speech-to-Sign: mikrofon → STT Bahasa Indonesia → pencocokan katalog isyarat → playlist video berurutan.

Input utama Speech-to-Sign adalah suara. Jangan mengganti alur utama menjadi form ketik. Pencarian teks di Perpustakaan tetap sesuai desain.

Produk yang sedang dibangun adalah Sign2Speech. Nama domain `hajicare-sign.web.app` merupakan konfigurasi hosting video dalam PRD, bukan instruksi untuk memasukkan fitur Smart Band, money recognition, atau peta HajiCare.

Contoh kalimat di PRD bersifat skenario, bukan bukti cakupan model/katalog atau keberhasilan penerjemahan. Playlist kata-demi-kata juga belum membuktikan kesetaraan tata bahasa isyarat alami; validasi konten bahasa tetap diperlukan.

## 3. Workspace dan status yang diketahui

Path Windows yang disebut pengguna: `C:\speech2sign`. Nama folder explorer pada screenshot: `speech2sign`. Identifikasi root aktif sebelum bekerja.

Screenshot menunjukkan proyek Flutter telah memiliki:
- `android/`, `ios/`, `lib/`.
- `assets/komponen_img/`: komponen gambar/ilustrasi terpisah.
- `assets/reference_design/`: 12 PNG referensi layar.
- `AGENTS.md`, `GEMINI.md`, `DESIGN.md`, `logic-sign.md`.
- PRD, implementation plan, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, dan `README.md`.

Keberadaan folder tidak membuktikan isi kode atau fungsi sudah selesai. Jangan membuat ulang proyek atau menimpa sumber yang sudah ada.

Pengguna menyatakan skill sudah diunduh. Status penemuan skill oleh agent, dependensi helper, dan koneksi MCP tetap harus diperiksa di lingkungan Antigravity. Tidak ada hasil build/test atau benchmark yang diberikan dalam obrolan ini.

## 4. Keputusan desain yang dikunci

**Gaya:** Cafe Warm Oat Milk / Espresso Playful Editorial; hangat, ramah, tenang, dengan ilustrasi editorial 2D dan whitespace lega.

| Token | Nilai | Pemakaian |
| --- | --- | --- |
| Primary (`AppColors.primary`) | `#2C1E18` | CTA utama, hero card, navigasi aktif (Rich Espresso) |
| Secondary (`AppColors.secondary`) | `#8C5A3C` | Waveform, ring konfirmasi, kata aktif (Warm Caramel) |
| Canvas (`AppColors.canvas`) | `#FDFBF7` | Latar utama aplikasi (Warm Oat Milk / Cream) |
| Surface (`AppColors.surface`) | `#FFFFFF` | Kartu elevated, modal, input, sheet (Pure Warm White) |
| BgSurface / Pale Mist (`AppColors.bgSurface`) | `#F4EFE6` | Latar kartu sekunder, chips, banner (Latte Foam) |
| Border (`AppColors.border`) | `#E6DCD2` | Outline kartu, input border, divider (Warm Sand) |
| Border Dashed (`AppColors.borderDashed`) | `#D5C7B8` | Garis putus-putus cafe ticket |
| Ink (`AppColors.ink`) | `#2C1E18` | Teks utama, heading, garis ilustrasi (Rich Espresso) |
| Muted (`AppColors.muted`) | `#6E5A4F` | Teks pendukung, subtitle, timer (Roasted Mocha) |
| Text Muted (`AppColors.textMuted`) | `#9A8679` | Placeholder & caption (Warm Taupe) |
| Matcha / Success (`AppColors.matcha`) | `#4A6B53` | Status offline & indikator sukses semantik |
| Amber / Warning (`AppColors.amber`) | `#D97724` | Badge, warning, highlight |
| Camera Dark (`AppColors.cameraDark`) | `#191210` | Latar viewfinder kamera & dark overlay |

Single Source of Truth terpusat di `AppColors` (`lib/core/theme/app_colors.dart`).

- Font **Plus Jakarta Sans** untuk seluruh UI; jangan mengganti dengan Inter atau Roboto default.
- Multi-bahasa dinamis via `AppStrings` & `AppTranslations` (`id_ID` & `en_US`) dengan getter `.tr` reaktif di dalam `Obx`.
- Karakter konsisten: wanita muda berambut ikal cepol dan pria muda berambut pendek; outline Rich Espresso (`#2C1E18`), fill putih hangat.
- Ilustrasi tangan dekoratif bukan representasi BISINDO/SIBI yang terverifikasi.
- Acuan artboard **393 × 852**; implementasi adaptif, bukan koordinat layar yang dibekukan.
- Spacing dasar: 4, 8, 16, 24, 32, 48.
- Heading halaman sekitar 24 px, hero 32 px, judul kartu 18 px, body 15–16 px; lihat DESIGN.md untuk weight/line height.
- Target sentuh minimum **48 × 48 dp**.
- Hormati safe area, text scaling, screen reader, serta reduced motion.
- Bottom navigation: **Beranda, Riwayat, Perpustakaan, Pengaturan**.
- Animasi sesuai state nyata: waveform saat mendengarkan, ring saat konfirmasi, progress saat playback/unduh.
- Pertahankan layout layar yang sudah disetujui; jangan membuat identitas visual baru.
- Jangan menambahkan purple/neon, karakter 3D, emoji navigasi, angka akurasi palsu, atau dekorasi yang menghalangi tangan/wajah kamera.

### Aset `komponen_img`

Gunakan komponen asli dari `assets/komponen_img/`, bukan mengganti seluruh ilustrasi secara otomatis. Periksa gambar satu per satu, petakan ke layar, buat registry aset, dan daftarkan pada pubspec.

Nama file lengkap komponen tidak terbaca dari screenshot; agent harus menginventarisasi file nyata. Jangan mengarang path aset.

Teks, tombol, kartu, input, navigasi, dan kontrol media harus berupa widget Flutter yang interaktif. Jangan meratakan screenshot/kolase menjadi UI. Pertahankan aspect ratio; ilustrasi utuh umumnya memakai `BoxFit.contain`. Jangan memotong wajah/tangan atau menumpuk ilustrasi di atas kontrol.

## 5. Layar dan alur navigasi

Nama berikut terlihat dalam screenshot; konfirmasi ejaan aktual di disk sebelum membuat referensi aset.

| No. | Referensi di `assets/reference_design/` | Fungsi wajib |
| --- | --- | --- |
| 01 | `01_Splash_Screen.png` | Brand, tagline, transisi startup |
| 02 | `02_Onboarding_1.png` | Penjelasan komunikasi dua arah |
| 03 | `03_Onboarding_2.png` | Konteks penggunaan sehari-hari/publik |
| 04 | `04_Pilih_Peran.png` | Dua kartu bertumpuk Teman Tuli/Teman Dengar |
| 05 | `05_Pilih_Jenis_Isyarat.png` | BISINDO/SIBI dan pilihan aktif |
| 06 | `06_Beranda.png` | Dua kartu fitur dan bottom navigation |
| 07 | `07_Sign_to_Speech_Kamera.png` | Preview kamera, switch model, status, ring, transkrip |
| 08 | `08_Hasil_Sign_to_Speech.png` | Teks, replay suara, simpan, kembali/ulangi |
| 09 | `09_Speech_to_Sign_Mikrofon.png` | Mikrofon, waveform, partial transcript, stop |
| 10 | `10_Hasil_Speech_to_Sign.png` | Video, kata aktif, replay, kecepatan, sumber offline |
| 11 | `11_Perpustakaan_Isyarat.png` | Search, kategori, status unduhan |
| 12 | `12_Pengaturan (1).png` | Bahasa, suara, kecepatan, offline, tema, history/about |

DESIGN.md juga menetapkan **layar 13 Riwayat**: entri lokal, waktu, arah terjemahan, filter, replay, dan konfirmasi hapus. Ini tambahan pada 12 referensi, bukan pengganti layar yang disetujui. Rancang konsisten tanpa mengklaim ada PNG referensi ke-13.

Alur awal: Splash → onboarding → pilih peran → pilih bahasa → Beranda. Simpan preferensi onboarding/peran/bahasa. Pengulangan onboarding pada peluncuran berikutnya harus mengikuti state tersimpan dan kebutuhan PRD.

Kategori contoh desain: Salam, Keluarga, Kesehatan, Belanja, Darurat, Layanan Publik. Kategori tambahan PRD: Transportasi & Arah, Transaksi Harian. Isi dan jumlah video harus mengikuti katalog nyata.

State tambahan: izin ditolak, kamera siap/paused, gestur ambigu, cahaya kurang jika dapat diukur, tangan di luar frame, STT idle/listening/processing/no speech, media loading/error/unavailable, online-only, downloaded, partial/interrupted download, empty history.

## 6. Stack dan arsitektur

**Keputusan tetap:** Flutter + Dart + **GetX** (`GetxController`, `Bindings`, `GetView`/`GetWidget`). Jangan migrasi sepihak ke BLoC, Riverpod, atau Provider.

Versi disebut dalam Project Rule: Flutter 3.47.x dan Dart 3.13.x. Itu konteks yang diberikan pengguna, bukan hasil pemeriksaan SDK. Gunakan versi runtime serta pubspec/lock aktual sebagai dasar kompatibilitas; jangan melakukan upgrade besar tanpa kebutuhan yang jelas.

Package dalam spesifikasi: `tflite_flutter`, `speech_to_text`, `flutter_tts`, `video_player`, `dio`, `path_provider`, `shared_preferences`; Android native CameraX dan MediaPipe.

| Lapisan | Tanggung jawab |
| --- | --- |
| Presentation | Widget, state UI, GetxController, routing/binding |
| Domain | Entitas murni, value objects, interface repository/use case |
| Data | Adapter kamera/ML/audio/video, repository implementasi, cache/persistence |

- Domain tidak bergantung pada GetX atau Flutter UI.
- Controller/domain/data tidak menyimpan BuildContext.
- Gunakan interface kamera/model untuk test tanpa hardware (`ICameraLandmarkService`, `IModelClassifier` dalam PRD).
- Katalog video dan state transkrip memiliki satu sumber otoritatif masing-masing.
- Tutup stream, subscription, timer, interpreter, executor, serta video controller pada lifecycle yang tepat.
- Path `models/services/controllers` di plan adalah usulan historis; adaptasikan ke pemisahan domain/data/presentation dalam Project Rule sambil mempertahankan fungsi.

Entitas yang direncanakan: LandmarkFrame, BisindoPrediction, SignToken, SignCaptureQuality, SignVideoEntry, SignSearchResult, SignLanguageCatalog, CategoryPackageInfo.

## 7. Sign-to-Speech: kontrak usulan yang wajib diverifikasi

**Penting:** parameter di bagian ini berasal dari PRD/plan. Belum divalidasi terhadap model dan kode training asli dalam sesi ini.

### Kamera dan transport data

- Android CameraX ImageAnalysis di executor background khusus.
- Backpressure `STRATEGY_KEEP_ONLY_LATEST` untuk menghindari penumpukan frame.
- EventChannel yang direncanakan: `com.sign2speech.bisindo/landmarks`.
- Sertakan timestamp, validitas frame, dan mask keberadaan sesuai kontrak nyata.
- Bersihkan NaN/Infinity/-Infinity ke 0.0; clamp mentah `[-10,10]` adalah ketentuan PRD yang juga harus dicocokkan dengan training.
- Payload, jumlah elemen, tipe codec, urutan titik, rotasi, dan mirroring harus didokumentasikan secara eksplisit. Instruksi `EventSink.success(floatArray)` dalam plan bukan bukti implementasi channel yang sudah berfungsi.

### Feature extractor 353-D dalam PRD

| Indeks inklusif | Fitur | Jumlah |
| --- | --- | --- |
| 0–62 | Left hand global, normalisasi pusat/jarak bahu, clamp `[-6,6]` | 63 |
| 63–125 | Left hand local, wrist/palm scale, clamp `[-5,5]` | 63 |
| 126–188 | Right hand global | 63 |
| 189–251 | Right hand local | 63 |
| 252–296 | Pose terpilih `0,11..24`, XYZ | 45 |
| 297–348 | Face blendshape coefficients | 52 |
| 349–352 | Mask `[left,right,pose,face]` | 4 |

Normalisasi global usulan: `(P - shoulderCenter) / (shoulderDistance + 1e-6)`.
Normalisasi lokal usulan: `(P - wrist) / (palmScale + 1e-6)`.
Definisi MCP/palmScale, mask, urutan blendshapes, dan missing-data policy harus berasal dari training, bukan tebakan.

### Temporal dan classifier

- Resample menjadi 48 timestep dengan interpolasi linier.
- Delta: `delta[t] = clamp(base[t] - base[t-1], -4,4)`, delta pertama nol.
- Usulan tensor input: `[1,48,706]`, 353 base + 353 delta; 33.888 nilai.
- PRD menyebut input Float32 dan model berbobot Float16. Periksa dtype tensor sebenarnya; nama model Float16 tidak berarti input juga Float16.
- Jumlah kelas PRD: BISINDO 47, SIBI 72; verifikasi labels dan output masing-masing model. Jangan memakai jumlah kelas model lama dari percakapan/proyek lain.
- Ambang usulan: confidence ≥ 0.70, top1-top2 margin ≥ 0.15.
- Periksa apakah output logits atau probabilities sebelum menerapkan softmax; jangan softmax ganda.

### Segmentasi dan keputusan penerimaan

| Parameter PRD/plan | Nilai usulan |
| --- | --- |
| Onset tangan stabil | ≥3 frame dengan motion energy memenuhi threshold |
| Akhir karena tangan hilang | >450 ms |
| Akhir karena diam | >750 ms |
| Durasi valid | 450–3500 ms |
| Idle ejaan | ≥1500 ms atau tombol Spasi |
| Cooldown duplikat | 1200 ms |
| Stabilitas prediksi dalam plan | 2–3 prediksi identik; belum diputuskan tepatnya |

`E_thresh` belum memiliki nilai dalam sumber; tidak boleh dianggap sudah ditentukan. Cooldown dan segmentasi perlu mengizinkan pengulangan kata/huruf yang disengaja, bukan menghapusnya tanpa evaluasi.

### Transkrip dan suara

- Kata utuh diterima → transkrip dan antrean TTS.
- Huruf A–Z/LETTER_* → buffer ejaan; baca kata utuh saat idle/Spasi.
- TTS `id-ID`, antrean serial FIFO; gunakan sinyal completion engine agar chaining Future benar-benar menunggu ucapan selesai.
- Simpan transkrip lokal melalui SharedPreferences sesuai PRD.
- Switch BISINDO/SIBI dan pause kamera mempertahankan transkrip.
- Reset eksplisit menghapus state yang relevan dengan penanganan timer/TTS agar hasil lama tidak masuk kembali.

### Performa

Offload ekstraksi, resampling, dan inferensi dari main UI isolate. Terapkan single-in-flight/skip guard. Pilihan `compute`/`Isolate.run` vs worker menetap harus dievaluasi terhadap overhead, transfer data, dan lifecycle interpreter; pemanggilan isolate saja tidak membuktikan zero lag.

## 8. Speech-to-Sign: perilaku wajib

1. Mulai mendengarkan melalui tombol mic dengan izin kontekstual.
2. Gunakan locale Bahasa Indonesia yang benar-benar tersedia di perangkat; PRD memberi `localeId: 'id'`, sedangkan TTS `id-ID`.
3. Partial result memperbarui teks; waveform berasal dari level suara jika tersedia.
4. `isFinal == true` menghentikan mic dan memulai pencarian otomatis tanpa tombol Cari tambahan.
5. Token generasi `_generation` menolak callback lama setelah stop/dispose/sesi berubah.

### Pencocokan hierarkis

Normalisasi lowercase, tanda baca, dan whitespace; pertahankan urutan ucapan.

| Urutan | Pencocokan | Contoh spesifikasi |
| --- | --- | --- |
| 1 | Exact full phrase | terima kasih → Terima Kasih |
| 2 | Alias frasa/kata | tolong → Bantu; karcis → Tiket |
| 3 | Token kata berurutan | saya mau beli tiket → Saya, Mau, Beli, Tiket |

Label/alias contoh harus diverifikasi terhadap katalog nyata. Jangan membuang kata yang tidak didukung secara diam-diam atau menampilkan seolah seluruh kalimat diterjemahkan. Detail fallback token/frasa dan coverage harus dicatat bila belum diputuskan.

### Playlist

- Putar video berurutan, highlight activeWordIndex.
- Play/pause, replay, Loop All/Loop Word, kecepatan 0.75×/1.0×/1.25×.
- `_playSessionId` naik pada input baru; hasil async dari sesi lama tidak boleh menimpa sesi baru.
- Dispose controller lama dengan aman; penanganan race harus diuji saat loading maupun playback.

### Resolusi video dan offline

Konfigurasi PRD: `https://hajicare-sign.web.app/videos/{language}/{slug}_v1.mp4`.
URL merupakan konfigurasi yang tercantum, belum dicek ketersediaan/otorisasinya dalam sesi ini. Jangan mengubah atau memublikasikan hosting hanya karena URL ada di dokumen.

| Prioritas | Sumber | Perilaku |
| --- | --- | --- |
| Tier 1 | Bundled `assets/videos/...` | Putar langsung dari asset |
| Tier 2 | Cache privat aplikasi | Putar berkas lokal yang valid |
| Tier 3 | Remote hosting | Stream sambil unduh background untuk cache berikutnya |

- Cache memakai application support directory sesuai PRD.
- Unduh kategori melalui Dio: file `.tmp`, validasi integritas yang tersedia, atomic rename setelah selesai.
- Jangan menandai file parsial sebagai offline-ready. Tangani retry, error, progress, dan pembatalan.
- Status UI jujur: Tersimpan offline, Mengunduh, Memerlukan internet, Video tidak tersedia.
- Offline video/AI tidak berarti STT pasti offline; kemampuan STT/TTS bergantung pada engine dan paket bahasa perangkat.

## 9. Konflik dan hal yang belum diverifikasi

| Isu | Fakta sumber | Tindakan agent |
| --- | --- | --- |
| Jumlah landmark/payload | PRD menyebut 543 XYZ, tetapi rincian raw mencantumkan pose 99 float + dua tangan 126 float + blendshapes 52 float = 277 nilai sebelum mask | Periksa training dan output native; bedakan landmark XYZ, scalar blendshapes, dan vektor fitur. Jangan memperbaiki dengan mengganti angka semata |
| Face landmarks vs blendshapes | Plan menulis Face 52 sebagai bagian titik, extractor menulis 52 coefficients | Tentukan API/model MediaPipe yang benar-benar digunakan dan urutan output |
| ML input | Float16 pada model, Float32 pada tensor PRD | Baca tensor input/output interpreter dan metadata |
| Kelas/label | BISINDO 47, SIBI 72 di PRD | Validasi kedua model dan labels, termasuk word/letter mapping |
| Jumlah layar | 12 referensi di screenshot; DESIGN.md menambahkan Riwayat ke-13 | Pertahankan 12 layar; tambahkan Riwayat sesuai kontrak navigasi |
| FPS dan zero lag | KPI kamera ≥30 FPS; bagian lain mengharapkan 30–60/60 FPS | Pisahkan preview FPS, UI FPS, analysis rate; benchmark tanpa menjanjikan angka |
| Aksesibilitas | PRD menyebut AAA dan angka kontras; DESIGN.md meminta pengujian AA atau lebih baik | Ukur pasangan warna/state; jangan mengklaim seluruh aplikasi AAA dari satu pasangan |
| Offline dan privasi STT | PRD mengarah ke offline-first dan suara sementara | Verifikasi perilaku engine OS/jaringan; jangan menjanjikan STT lokal tanpa bukti |
| Struktur clean architecture | Plan memakai folder models/services; Project Rule menetapkan tiga lapisan | Ikuti tanggung jawab layer, sesuaikan path tanpa kehilangan fungsi |
| Nilai/aturan belum final | Motion energy threshold, 2–3 prediksi stabil, fallback kata tak tersedia | Catat sebagai keputusan terbuka; test dan dokumentasikan pilihan |
| Aset, model, video, MCP | Screenshot membuktikan folder, bukan integrasi | Inventarisasi dan uji di workspace pengguna |

Tidak membuat skill custom MotionGRU sebelum kontrak model/training diverifikasi, sesuai Project Rule.

## 10. Target evaluasi: bukan hasil yang sudah dicapai

| Target PRD | Nilai | Bukti yang diperlukan |
| --- | --- | --- |
| Top-1 gesture accuracy | ≥92% | Dataset evaluasi terpisah, metrik per kelas/overall |
| Ekstraksi + inference/window | ≤45 ms | Benchmark pada device target dan konfigurasi nyata |
| STT final → video pertama | ≤800 ms | Pengukuran end-to-end dengan kondisi cache/network |
| Serial FIFO audio | 100% tanpa overlap | Test completion/cancel serta uji perangkat |
| Offline kosakata inti | 100% katalog inti | Inventaris video valid dan uji tanpa jaringan |
| Preview kamera | ≥30 FPS | Pengukuran kamera saat inferensi aktif |

Helio G99/Snapdragon 680 merupakan contoh target dalam PRD, bukan perangkat yang telah diuji. Angka 98% nonpenutur isyarat dalam latar belakang PRD juga belum memiliki sumber terverifikasi di sesi ini; jangan jadikan klaim publik tanpa referensi.

## 11. Privasi dan kepercayaan

- Implementasi yang dituju memproses kamera/landmark/inference secara lokal tanpa upload frame atau penyimpanan rekaman permanen.
- Simpan preferensi dan transkrip lokal sesuai PRD; pengguna memiliki tindakan reset/hapus.
- Minta CAMERA dan RECORD_AUDIO saat fitur terkait dibuka dan jelaskan penggunaannya.
- Periksa perilaku STT engine secara terpisah; jangan mengklaim audio tidak pernah keluar perangkat tanpa bukti.
- Pisahkan video kamus yang diunduh dari video/rekaman pengguna.
- Tidak memasukkan API key/secret yang pernah muncul di obrolan ke dokumen atau repository.
- UU PDP dalam PRD merupakan arah kepatuhan; bukan sertifikasi/audit hukum yang sudah selesai.

## 12. Agent skills dan cara menggunakannya

Pengguna sudah meminta pengunduhan skill dan memberikan mapping berikut. Nama di tabel adalah nama yang disebut Project Rule, bukan hasil audit instalasi pada sesi ini.

| Tugas | Skill yang disebut pengguna |
| --- | --- |
| UI/UX | ui-ux-pro-max, design-system, stitch-generate-design, stitch-manage-design-system |
| Flutter/Dart | flutter-apply-architecture-best-practices, flutter-build-responsive-layout, flutter-fix-layout-issues, flutter-implement-json-serialization, dart-* |
| Eksekusi/test/review | executing-plans, subagent-driven-development, test-driven-development, systematic-debugging, verification-before-completion, requesting-code-review |
| Android native | android-dev, kotlin-coroutines-expert |
| Thermal/performance | diagnose-android-overheating |
| Edge states | ui-states |
| Aksesibilitas | accessibility-compliance-accessibility-audit |
| Dokumentasi | context7-mcp, context7-cli, find-docs |

Repositori yang direkomendasikan di obrolan:
- https://github.com/nextlevelbuilder/ui-ux-pro-max-skill
- https://github.com/flutter/agent-plugins
- https://github.com/obra/superpowers
- https://github.com/google-labs-code/stitch-skills
- https://github.com/sickn33/agentic-awesome-skills
- https://github.com/upstash/context7

Muat skill per tugas. Skill umum tidak boleh mengganti identitas desain/GetX atau menentukan kontrak model dengan asumsi. Dokumentasi harus sesuai versi dependency aktual. Verifikasi dukungan flag `--stack flutter` sebelum menjalankan helper UI UX Pro Max; jangan menganggap sintaks antarrelease selalu sama.

Skill Stitch dan koneksi Stitch MCP adalah dua hal berbeda. Proyek Stitch yang disebut pengguna: `https://stitch.google.com/projects/522036547427070342`, bernama Sign2Speech. Jangan menghapus/membuat ulang layar yang telah disetujui. Akses live dan autentikasi belum dibuktikan dalam sesi ini.

## 13. Urutan implementasi

Plan asli membagi pekerjaan menjadi sembilan task:
1. Domain entities/core contracts dan sanitasi.
2. Speech-to-Sign repository/search/cache/STT.
3. Controller/playlist dan session safety.
4. Feature extractor/sequence buffer.
5. Segmenter/TFLite classifier.
6. Recognition controller, spelling buffer, FIFO TTS, transcript store.
7. Native CameraX/MediaPipe channel.
8. Design tokens/widget.
9. Screens, bindings, integrasi.

Arahan implementasi terbaru dari obrolan melengkapinya dengan: audit proyek → fondasi/tema/aset/routing → seluruh layar/navigasi → persistence → dua fitur inti → test/visual QA/build. Susun dependency task tanpa kehilangan cakupan sembilan task. Roadmap tanggal dalam PRD adalah rencana historis, bukan bukti pekerjaan sudah dijalankan.

### Jika artefak ML/media belum tersedia

Lanjutkan UI, domain, service interfaces, navigasi, dan test yang tidak terhambat. Production state harus menunjukkan fitur/model/video belum tersedia. Mock hanya untuk automated test atau mode demo yang diberi label; jangan memasukkan prediksi palsu ke mode normal.

## 14. Verifikasi dan definisi selesai

- Format Dart, `flutter analyze`, test yang relevan, serta build APK debug.
- Tes perilaku: sanitasi, preprocessing, resampling, threshold, segmentasi, ejaan, FIFO completion, session cancellation, matching, tier cache, unduhan terputus, dan persistence.
- Bandingkan preprocessing Python vs Dart dengan fixture identik, urutan fitur yang sama, dan toleransi numerik yang ditetapkan.
- Widget/integration test untuk navigasi, permission states, controls, switch bahasa, replay, reset, dan offline.
- Periksa screenshot per layar terhadap referensi: layout, font, warna, aspect ratio, overflow, safe area, text scale, dan touch targets.
- Uji perangkat untuk kamera, mic, TFLite, TTS, STT, lifecycle/background-resume, serta playback. Mock lulus tidak membuktikan integrasi hardware.
- Review resource disposal, error recovery, dan async race.
- README berisi cara run, konfigurasi, sumber artefak, dan batasan yang tersisa.
- Laporkan fitur selesai, test/build yang benar-benar dijalankan, screenshot, serta hambatan spesifik.

Build berhasil tidak otomatis berarti seluruh fitur selesai; UI lengkap tidak otomatis berarti model terintegrasi. Nyatakan setiap status berdasarkan bukti.

## 15. Instruksi singkat untuk agent yang melanjutkan

1. Baca AGENTS.md, GEMINI.md, Project Rule, dokumen sumber, lalu konteks ini.
2. Audit workspace nyata; pertahankan perubahan pengguna.
3. Inventarisasi skill, aset komponen, referensi, model, metadata, labels, training, dan video.
4. Catat konflik/blocker; mulai pekerjaan independen yang sudah diotorisasi.
5. Bangun Flutter + GetX mengikuti desain dan perilaku PRD dengan widget/aset terpisah.
6. Verifikasi kontrak ML sebelum implementasi produksi dan jangan membuat skill ML custom lebih awal.
7. Uji, review visual, build, dan perbarui status konteks hanya berdasarkan pekerjaan yang terbukti.

**Kondisi awal pada akhir obrolan ini:** dokumen, referensi, aturan proyek, serta prompt instalasi/implementasi tersedia. Pengguna menyatakan skill sudah diunduh. Kode aplikasi, keberhasilan skill discovery/MCP, kontrak model, media coverage, dan hasil QA masih perlu diverifikasi langsung oleh Antigravity di workspace pengguna.
