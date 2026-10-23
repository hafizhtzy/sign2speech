# Sign2Speech: Implementation Plan (Sign-to-Speech & Speech-to-Sign)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun sistem aksesibilitas komunikasi dua arah untuk aplikasi **Sign2Speech**: penerjemah visual gestur kamera ke suara bahasa Indonesia (Sign-to-Speech) dan penangkap suara ke peragaan video isyarat berurutan (Speech-to-Sign) untuk percakapan sehari-hari dan pelayanan publik berbasis Flutter Clean Architecture dan GetX.

**Architecture:** Arsitektur modular 3-lapisan (Presentation, Domain, Data) berbasis Clean Architecture resmi Flutter dan GetX. Data layer mengisolasi MediaPipe Holistic 543 titik, ekstraksi 353 fitur spasial + 353 delta velocity (706-D), inferensi TFLite MotionGRU, antrean serial FIFO TTS, penangkapan suara STT, dan pencocokan video berjenjang (3-tier offline-first). Seluruh komunikasi perangkat keras diikat melalui interface abstrak dengan mock fixtures untuk pengujian TDD instan.

**Tech Stack:** 
- Framework: Flutter & Dart 3.x
- State Management & DI: GetX (`GetxController`, `Bindings`)
- Machine Learning: TFLite Flutter (`tflite_flutter`), Float16 MotionGRU Model (BISINDO 47 kelas, SIBI 72 kelas)
- Computer Vision: MediaPipe Holistic via Android Native CameraX EventChannel (`com.sign2speech.bisindo/landmarks`)
- Audio & Video: `speech_to_text`, `flutter_tts`, `video_player`
- Networking & Cache: `dio`, `path_provider`, `shared_preferences`
- Design Tokens: Cafe Warm Oat Milk / Espresso (`#2C1E18`, `#8C5A3C`, `#FDFBF7`, `#FFFFFF`, `#F4EFE6`, `#E6DCD2`, `#6E5A4F`, `#4A6B53`, `#D97724`)

**Spec:** [docs/superpowers/specs/2026-10-13-sign-and-speech-prd.md](file:///c:/fadli/Antigravity-Skill-Brain/docs/superpowers/specs/2026-10-13-sign-and-speech-prd.md)

---

## Global Constraints

- Flutter Clean Architecture: Tidak ada dependensi `BuildContext` di dalam controller atau data layer.
- Zero-Lag Camera Pipeline: CameraX ImageAnalysis wajib dikonfigurasi dengan `STRATEGY_KEEP_ONLY_LATEST` pada thread latar belakang terdedikasi (`Executors.newSingleThreadExecutor()`). Ekstraksi fitur 353D dan kalkulasi sekuens 706D wajib di-offload ke background Dart Isolate (`Isolate.run` / `compute`) agar Main UI Thread stabil pada 60 FPS tanpa frame drop.
- Video CDN Hosting & Cache-on-Play: Base URL video hosting disetel ke `https://hajicare-sign.web.app/videos/{language}/{slug}_v1.mp4` (didukung offline Tier 1 APK asset & Tier 2 local cache). Pemutaran Tier 3 memutar streaming video secara langsung seraya mengunduh asinkron ke Tier 2 disk cache lokal.
- Thread & Memory Safety: Semua stream controller, event channel subscription, dan video player controller wajib ditutup pada `onClose()`.
- TTS Non-Overlapping: Pengucapan audio TTS Bahasa Indonesia (`id-ID`) wajib dieksekusi secara serial FIFO melalui rantai `Future` (`_speechChain`).
- Race-Free Playback: Sesi pemutaran video wajib dilindungi token `_playSessionId` yang diincrement setiap kali kueri suara baru masuk.
- Data Sanitization: Semua koordinat MediaPipe wajib melewati sanitasi numerik (mengubah `NaN` dan `Infinite` menjadi `0.0`).
- Model Confidence: Ambang batas deteksi gestur MotionGRU minimal `confidence >= 0.70` dengan selisih probabilitas Top-1 vs Top-2 `margin >= 0.15`.
- Offline First: Sumber video isyarat memprioritaskan Tier 1 (Asset APK), Tier 2 (Local Storage Cache), dan Tier 3 (Remote CDN Firebase Hosting).
- Download Atomicity: Unduhan kategori video wajib menggunakan ekstensi berkas sementara `.tmp` dan mekanisme *atomic rename*.

---

## Review Focus

1. **Kamera Lag & Frame Drop saat Inferensi**: Komputasi ekstraksi 353 fitur dan inferensi TFLite di Main UI Thread memicu stutter visual dan jank kamera. Solusi: offload ke background Dart Isolate (`Isolate.run`) dan CameraX `STRATEGY_KEEP_ONLY_LATEST`.
2. **Koordinat Rusak dari Kamera Native**: Landmark MediaPipe menghasilkan nilai `NaN`, `-Infinity`, atau koordinat di luar jangkauan saat tangan tertutup sebagian, menyebabkan crash pada ekstraksi normalisasi matematika jika tidak disanitasi.
3. **Audio Clashing pada Ucapan Beruntun**: Pengguna menggerakkan gestur kata berturut-turut dengan cepat sebelum ucapan TTS kata sebelumnya selesai, berpotensi memotong suara kata pertama jika tidak diantrekan via serial FIFO queue.
4. **Patahan Pengucapan Ejaan Huruf**: Menghindari pembacaan alfabet satu-satu (*"B" ... "E" ... "L" ... "I"*) dengan mengumpulkan ejaan ke buffer dan membacakan kata utuh (*"BELI"*) setelah jeda $1500\text{ ms}$ atau spasi.
5. **Race Condition Suara STT Cepat**: Pengguna berbicara berulang kali secara cepat saat mikrofon aktif, menyebabkan video yang sedang dimuat dari ucapan pertama menimpa video dari ucapan kedua jika tidak dilindungi `_playSessionId`.

---

## Task Decomposition

### Task 1: Domain Entities & Core Contracts

**Files:**
- Create: `lib/features/sign_language/models/landmark_frame.dart`
- Create: `lib/features/sign_language/models/bisindo_prediction.dart`
- Create: `lib/features/sign_language/models/sign_token.dart`
- Create: `lib/features/sign_language/models/sign_capture_quality.dart`
- Create: `lib/features/sign_language/models/sign_video_entry.dart`
- Create: `lib/features/sign_language/models/sign_search_result.dart`
- Create: `lib/features/sign_language/models/sign_language_catalog.dart`
- Create: `test/features/sign_language/models/domain_models_test.dart`

**Interfaces:**
- Consumes: Dart core primitives
- Produces: 
  - `LandmarkFrame(List<double> landmarks, int timestampMs, bool isValid)` dengan sanitasi `sanitizeLandmarks(List<double> raw)`
  - `BisindoPrediction(String label, double confidence, double margin, bool isLetter)`
  - `SignToken(String value, SignTokenType type, DateTime timestamp)`
  - `SignVideoEntry(String id, String label, List<String> aliases, String category, String assetPath, String remoteUrl)`
  - `SignSearchResult(String query, List<SignVideoEntry> matchedEntries, SearchMatchType matchType)`

- [ ] **Step 1: Write failing unit test for Domain Models & Sanitization**
  - Uji deserialisasi `LandmarkFrame` dari 543 koordinat, pastikan elemen bernilai `double.nan` atau `double.infinity` dikonversi ke `0.0`.
  - Uji `SignVideoEntry` dan `SignSearchResult` untuk pencocokan token dan serialisasi.

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/models/domain_models_test.dart`
  - Expected: FAIL ("classes not found")

- [ ] **Step 3: Implement domain models in `lib/features/sign_language/models/`**
  - Implementasikan seluruh entitas domain dengan `const constructor`, validasi immutability, dan helper method sanitasi numerik.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/models/domain_models_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/features/sign_language/models/ test/features/sign_language/models/ && git commit -m "feat(sign_language): implement domain entities and models with landmark sanitization"`

---

### Task 2: Speech-to-Sign Data Layer & Repository (Search, Video Hosting & Offline Cache)

**Files:**
- Create: `lib/features/sign_language/services/sign_language_config.dart`
- Create: `lib/features/translator/services/speech_service.dart`
- Create: `lib/features/sign_language/services/sign_language_asset_registry.dart`
- Create: `lib/features/sign_language/services/sign_language_cache_service.dart`
- Create: `lib/features/sign_language/services/sign_language_repository.dart`
- Create: `test/features/sign_language/services/sign_language_repository_test.dart`

**Interfaces:**
- Consumes: `SignVideoEntry`, `SignSearchResult`, `SignLanguageCatalog`
- Produces:
  - `SignLanguageConfig(baseUrl: 'https://hajicare-sign.web.app')`
  - `SpeechService.startListening({required String languageCode, required Function(String text, bool isFinal) onResult})`
  - `SignLanguageRepository.searchSign(String query, String languageCode) -> Future<SignSearchResult>`
  - `SignLanguageRepository.resolveVideoSource(SignVideoEntry entry) -> Future<String>` (Tier 1: Asset $\rightarrow$ Tier 2: Local cache $\rightarrow$ Tier 3: CDN URL dengan trigger download asinkron di background)
  - `SignLanguageRepository.downloadCategory(String categoryId, Function(double progress)? onProgress) -> Future<bool>`

- [ ] **Step 1: Write failing unit test for Hierarchical Search & Hybrid Video Source Resolution**
  - Uji skenario pencarian percakapan publik & harian:
    1. Exact match: input `"terima kasih"` mencocokkan video berlabel `"Terima Kasih"`.
    2. Alias match: input `"karcis"` atau `"tolong"` mencocokkan video dengan alias `"Tiket"` atau `"Bantu"`.
    3. Tokenized match: input `"saya mau beli tiket"` memecah dan menghasilkan daftar video berurutan `["Saya", "Mau", "Beli", "Tiket"]`.
  - Uji resolusi video 3-tier: 
    * Tier 1 (Asset bawaan APK ada $\rightarrow$ return asset path langsung).
    * Tier 2 (Cache lokal HP ada $\rightarrow$ return local file path).
    * Tier 3 (Fallback remote $\rightarrow$ return CDN URL `https://hajicare-sign.web.app/videos/...` dan memicu background caching asinkron ke Tier 2).
  - Uji unduhan kategori dengan mekanisme `.tmp` dan *atomic rename*.

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/services/sign_language_repository_test.dart`
  - Expected: FAIL

- [ ] **Step 3: Implement Config, SpeechService, Asset Registry, Cache Service, & Repository**
  - Implementasikan `SignLanguageConfig` dengan konstanta base hosting `https://hajicare-sign.web.app`.
  - Implementasikan `SpeechService` dengan `_generation` token untuk lifecycle safety.
  - Implementasikan `SignLanguageRepository` dengan algoritma pembersihan teks, pencarian hierarkis, cache-on-play streaming, dan unduhan atomik via Dio.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/services/sign_language_repository_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/features/sign_language/services/sign_language_config.dart lib/features/translator/services/ lib/features/sign_language/services/ test/features/sign_language/services/ && git commit -m "feat(speech_to_sign): implement hierarchical search repository, CDN video hosting resolver and cache-on-play"`

---

### Task 3: Speech-to-Sign Controller & Sequential Playlist Engine

**Files:**
- Create: `lib/features/sign_language/controllers/text_to_sign_controller.dart`
- Create: `lib/features/sign_language/bindings/text_to_sign_binding.dart`
- Create: `test/features/sign_language/controllers/text_to_sign_controller_test.dart`

**Interfaces:**
- Consumes: `SpeechService`, `SignLanguageRepository`, `SignSearchResult`, `SignVideoEntry`
- Produces:
  - `TextToSignController.toggleVoiceRecognition()`
  - `TextToSignController.activeWordIndex` (RxInt untuk melacak kata yang sedang diputar)
  - `TextToSignController.playlist` (RxList<SignVideoEntry>)
  - `TextToSignController.playSessionId` (Pelindung race condition)
  - `TextToSignController.onVideoFinished()` (Transisi ke video berikutnya dalam playlist sekuensial)

- [ ] **Step 1: Write failing unit test for TextToSignController**
  - Uji `toggleVoiceRecognition()`: mikrofon aktif, status mendengarkan berubah menjadi true.
  - Uji saat `isFinal == true`: mikrofon otomatis berhenti, pencarian dipicu otomatis, playlist terisi.
  - Uji `_playSessionId`: ketika input suara kedua masuk saat video pertama sedang disiapkan, sesi pemutaran pertama dibatalkan dan digantikan oleh sesi kedua.
  - Uji transisi playlist: `onVideoFinished()` menaikkan `activeWordIndex` dan memutar video berikutnya hingga akhir playlist, lalu looping jika diaktifkan.

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/controllers/text_to_sign_controller_test.dart`
  - Expected: FAIL

- [ ] **Step 3: Implement TextToSignController & TextToSignBinding in GetX**
  - Terapkan logika state reaktif GetX (`RxBool isListening`, `RxString recognizedWords`, `RxList playlist`, `RxInt activeWordIndex`).
  - Hubungkan dengan `VideoPlayerController` dan penanganan siklus hidup `onClose()`.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/controllers/text_to_sign_controller_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/features/sign_language/controllers/text_to_sign_controller.dart lib/features/sign_language/bindings/text_to_sign_binding.dart test/features/sign_language/controllers/ && git commit -m "feat(speech_to_sign): implement TextToSignController with sequential playlist and session safety"`

---

### Task 4: Sign-to-Speech Feature Extraction & Temporal Resampling Buffer (Zero-Lag Isolate Pipeline)

**Files:**
- Create: `lib/features/sign_language/services/bisindo_feature_extractor.dart`
- Create: `lib/features/sign_language/services/bisindo_sequence_buffer.dart`
- Create: `test/features/sign_language/services/feature_extractor_test.dart`
- Create: `test/features/sign_language/services/sequence_buffer_test.dart`

**Interfaces:**
- Consumes: `LandmarkFrame` (543 titik: Pose 33, Left Hand 21, Right Hand 21, Face 52)
- Produces:
  - `BisindoFeatureExtractor.extract(LandmarkFrame frame) -> Float32List` (Vektor berukuran tepat 353 float)
  - `BisindoFeatureExtractor.extractAsync(LandmarkFrame frame) -> Future<Float32List>` (Offload via `Isolate.run` untuk zero UI lag)
  - `BisindoSequenceBuffer.addFrame(Float32List features)`
  - `BisindoSequenceBuffer.buildModelTensor() -> Float32List` (Tensor berukuran `[1, 48, 706]` Float32 dengan interpolasi linier 1D dan velocity delta)
  - `BisindoSequenceBuffer.buildModelTensorAsync() -> Future<Float32List>` (Offload via `Isolate.run` tanpa membebani Main UI Thread)

- [ ] **Step 1: Write failing unit test for 353 Feature Extractor & 706-D Buffer**
  - Uji `BisindoFeatureExtractor`: berikan 543 koordinat, verifikasi output tepat 353 elemen:
    * `0..62`: Left hand global (normalisasi bahu, clamped `[-6.0, 6.0]`)
    * `63..125`: Left hand local (normalisasi wrist, clamped `[-5.0, 5.0]`)
    * `126..188`: Right hand global (clamped `[-6.0, 6.0]`)
    * `189..251`: Right hand local (clamped `[-5.0, 5.0]`)
    * `252..296`: 15 landmark pose terpilih ($15 \times 3 = 45$)
    * `297..348`: 52 face blendshapes
    * `349..352`: 4 mask keberadaan `[hasLeft, hasRight, hasPose, hasFace]`
  - Uji `BisindoSequenceBuffer`: berikan 20 frame atau 80 frame mentah, verifikasi output tepat $48 \times 706 = 33.888$ float (353 base + 353 delta kecepatan clamped `[-4.0, 4.0]`).
  - Uji `extractAsync` dan `buildModelTensorAsync` berjalan sukses di background isolate.

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/services/feature_extractor_test.dart test/features/sign_language/services/sequence_buffer_test.dart`
  - Expected: FAIL

- [ ] **Step 3: Implement BisindoFeatureExtractor and BisindoSequenceBuffer with Isolate Worker**
  - Implementasikan normalisasi vektor tubuh, kalkulasi jarak bahu dan skala telapak tangan.
  - Implementasikan interpolasi linier temporal 1D untuk resampling 48 timestep dan diferensiasi orde pertama ($\Delta[t] = \text{Base}[t] - \text{Base}[t-1]$).
  - Terapkan `Isolate.run()` wrapper agar operasi matematika berat berjalan di worker thread tanpa menyebabkan UI jank/lag.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/services/feature_extractor_test.dart test/features/sign_language/services/sequence_buffer_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/features/sign_language/services/bisindo_feature_extractor.dart lib/features/sign_language/services/bisindo_sequence_buffer.dart test/features/sign_language/services/ && git commit -m "feat(sign_to_speech): implement 353-D feature extractor and 706-D sequence buffer with zero-lag Isolate pipeline"`

---

### Task 5: Sign Spotting, Segmentation & TFLite Classifier

**Files:**
- Create: `lib/features/sign_language/services/bisindo_segmenter.dart`
- Create: `lib/features/sign_language/services/bisindo_classifier_service.dart`
- Create: `test/features/sign_language/services/segmenter_test.dart`
- Create: `test/features/sign_language/services/classifier_service_test.dart`

**Interfaces:**
- Consumes: `Float32List` tensor `[1, 48, 706]`, `LandmarkFrame`
- Produces:
  - `BisindoSegmenter.processFrame(LandmarkFrame frame) -> SegmentEvent?` (Onset: 3 frame tangan berturut-turut, Offset: tangan hilang $>450\text{ms}$ atau diam $>750\text{ms}$)
  - `BisindoClassifierService.classify(Float32List tensor, {required SignLanguageModel model}) -> Future<BisindoPrediction?>`
  - Threshold validasi: `confidence >= 0.70`, `margin >= 0.15`

- [ ] **Step 1: Write failing unit test for Sign Spotting and Classifier Filter**
  - Uji `BisindoSegmenter`: simulasi kemunculan tangan $<3$ frame diabaikan, tangan stabil $>3$ frame memicu onset, jeda tangan hilang $500\text{ms}$ memicu offset.
  - Uji `BisindoClassifierService`: verifikasi output prediksi disaring jika confidence $<0.70$ atau margin $<0.15$ (mengembalikan null).

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/services/segmenter_test.dart test/features/sign_language/services/classifier_service_test.dart`
  - Expected: FAIL

- [ ] **Step 3: Implement BisindoSegmenter and BisindoClassifierService**
  - Terapkan pemantauan energi kinetik tangan (*motion energy*) untuk segmentasi otomatis.
  - Terapkan pemuatan model TFLite MotionGRU (SIBI 72 kelas dan BISINDO 47 kelas) dengan kalkulasi softmax probability dan selisih Top-1 vs Top-2.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/services/segmenter_test.dart test/features/sign_language/services/classifier_service_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/features/sign_language/services/bisindo_segmenter.dart lib/features/sign_language/services/bisindo_classifier_service.dart test/features/sign_language/services/ && git commit -m "feat(sign_to_speech): implement automatic sign spotting segmenter and TFLite classifier"`

---

### Task 6: Sign-to-Speech Controller, Spelling Buffer & Serial FIFO TTS

**Files:**
- Create: `lib/features/sign_language/services/bisindo_tts_service.dart`
- Create: `lib/features/sign_language/services/sign_transcript_store.dart`
- Create: `lib/features/sign_language/controllers/bisindo_recognition_controller.dart`
- Create: `lib/features/sign_language/controllers/sign_language_controller.dart`
- Create: `test/features/sign_language/controllers/recognition_controller_test.dart`

**Interfaces:**
- Consumes: `BisindoPrediction`, `BisindoClassifierService`, `BisindoSegmenter`
- Produces:
  - `BisindoTtsService.speak(String text) -> Future<void>` (Serial FIFO queue via `_speechChain`)
  - `BisindoRecognitionController.handlePrediction(BisindoPrediction prediction)`
  - `SignLanguageController.holdProgress` (0.0 sampai 1.0)
  - `SignTranscriptStore.saveTranscript(List<SignToken> tokens)`

- [ ] **Step 1: Write failing unit test for Recognition Controller & TTS FIFO Queue**
  - Uji filter stabilitas: minimal 2-3 prediksi identik berturut-turut sebelum kata diterima.
  - Uji cooldown duplikat: kata identik yang muncul dalam $<1200\text{ms}$ tidak di-commit dua kali.
  - Uji buffer ejaan: huruf `LETTER_B`, `LETTER_E`, `LETTER_L`, `LETTER_I` tidak diucapkan satu per satu, melainkan ditampung. Setelah idle $1500\text{ms}$ atau spasi, TTS dipanggil untuk kata utuh `"BELI"`.
  - Uji antrean FIFO TTS: pastikan ucapan beruntun menunggu ucapan sebelumnya selesai tanpa tumpang-tindih.
  - Uji persistensi transkrip: perpindahan model SIBI $\leftrightarrow$ BISINDO tidak menghapus daftar transkrip.

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/controllers/recognition_controller_test.dart`
  - Expected: FAIL

- [ ] **Step 3: Implement TTS Service, Transcript Store, & Controllers**
  - Implementasikan `BisindoTtsService` dengan rantai `_speechChain = _speechChain.then(...)`.
  - Terapkan logika buffer huruf ejaan dengan `Timer letterSpeechTimer` berdurasi $1500\text{ms}$.
  - Terapkan persistensi transkrip di `SignTranscriptStore` berbasis `SharedPreferences`.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/controllers/recognition_controller_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/features/sign_language/services/bisindo_tts_service.dart lib/features/sign_language/services/sign_transcript_store.dart lib/features/sign_language/controllers/ test/features/sign_language/controllers/ && git commit -m "feat(sign_to_speech): implement recognition controller with letter spelling buffer and FIFO TTS queue"`

---

### Task 7: Native Android CameraX & MediaPipe Holistic Platform Channel Contract (Zero-Lag Camera Pipeline)

**Files:**
- Create: `lib/features/sign_language/services/bisindo_camera_landmark_service.dart`
- Create: `lib/features/sign_language/services/mock_camera_landmark_service.dart`
- Create: `android/app/src/main/kotlin/com/sign2speech/bisindo/MediaPipeHolisticPlugin.kt`
- Create: `test/features/sign_language/services/camera_landmark_service_test.dart`

**Interfaces:**
- Consumes: Android EventChannel `'com.sign2speech.bisindo/landmarks'`
- Produces:
  - `ICameraLandmarkService.landmarkStream -> Stream<LandmarkFrame>`
  - `MockCameraLandmarkService` untuk pengujian TDD tanpa kamera fisik
  - `MediaPipeHolisticPlugin.kt` spesifikasi integrasi native CameraX non-blocking (`STRATEGY_KEEP_ONLY_LATEST` pada `Executors.newSingleThreadExecutor()`) ke EventChannel

- [ ] **Step 1: Write failing unit test for Landmark Service & Stream Parser**
  - Uji `BisindoCameraLandmarkService`: menerima stream dari channel `'com.sign2speech.bisindo/landmarks'`, mem-parsing 543 koordinat, dan menyaring nilai korup secara otomatis.
  - Uji `MockCameraLandmarkService`: dapat mengalirkan frame sintetis untuk kebutuhan automated testing.

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/services/camera_landmark_service_test.dart`
  - Expected: FAIL

- [ ] **Step 3: Implement Landmark Services and Native Kotlin Non-Blocking Specifications**
  - Implementasikan interface `ICameraLandmarkService` di Dart beserta `MockCameraLandmarkService`.
  - Tulis implementasi `BisindoCameraLandmarkService` yang berlangganan ke `EventChannel('com.sign2speech.bisindo/landmarks')` dengan drop-frame throttling jika UI sedang sibuk.
  - Tulis spesifikasi implementasi `MediaPipeHolisticPlugin.kt`:
    * Alokasikan CameraX `ImageAnalysis` dengan `.setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)`.
    * Jalankan Image Analyzer di background thread pool terdedikasi `Executors.newSingleThreadExecutor()` (bukan Main UI Thread Android).
    * Stream hasil 543 koordinat via `EventChannel.EventSink.success(floatArray)`.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/services/camera_landmark_service_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/features/sign_language/services/bisindo_camera_landmark_service.dart lib/features/sign_language/services/mock_camera_landmark_service.dart android/ test/features/sign_language/services/ && git commit -m "feat(sign_to_speech): implement zero-lag CameraX MediaPipe Holistic native plugin contracts and mock service"`

---

### Task 8: UI Components & Cafe Warm Oat Milk / Espresso Design Tokens

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/features/sign_language/widgets/sign_speech_card.dart`
- Create: `lib/features/sign_language/widgets/sign_search_voice_bar.dart`
- Create: `lib/features/sign_language/widgets/sign_video_player.dart`
- Create: `lib/features/sign_language/widgets/hold_confirm_ring.dart`
- Create: `test/features/sign_language/widgets/widgets_test.dart`

**Interfaces:**
- Consumes: GetX controllers, Theme tokens
- Produces:
  - `AppColors`: Rich Espresso (`#2C1E18`), Warm Caramel (`#8C5A3C`), Warm Oat Milk (`#FDFBF7`), Pure Warm White (`#FFFFFF`), Soft Latte Foam (`#F4EFE6`), Warm Sand Border (`#E6DCD2`), Roasted Mocha (`#6E5A4F`), Matcha Sage (`#4A6B53`), Amber Gold (`#D97724`)
  - `SignSpeechCard`: Kartu perekam suara dengan animasi visualizer gelombang audio reaktif
  - `SignVideoPlayer`: Pemutar video berulang dengan indikator badge kata aktif
  - `HoldConfirmRing`: Cincin progres melingkar $0\% \rightarrow 100\%$ untuk feedback gestur

- [ ] **Step 1: Write failing widget test for Design Tokens & Custom Widgets**
  - Uji `SignSpeechCard`: menampilkan teks ucapan dan ikon mic aktif dengan palet Cafe Warm Oat Milk / Espresso.
  - Uji `HoldConfirmRing`: menampilkan progres $0.0$ hingga $1.0$ dengan warna aksen Warm Caramel.
  - Uji `SignVideoPlayer`: menampilkan indikator kata aktif yang sesuai dengan `activeWordIndex`.

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/widgets/widgets_test.dart`
  - Expected: FAIL

- [ ] **Step 3: Implement Design Tokens & Widgets**
  - Buat `AppColors` dan `AppTheme` dengan palet Cafe Warm Oat Milk / Espresso.
  - Terapkan animasi mikrointeraksi pada cincin konfirmasi dan gelombang audio responsif.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/widgets/widgets_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/core/theme/ lib/features/sign_language/widgets/ test/features/sign_language/widgets/ && git commit -m "feat(ui): implement Cafe Warm Oat Milk / Espresso design tokens and accessibility widgets"`

---

### Task 9: Screens, DI Bindings & Integration Wiring

**Files:**
- Create: `lib/features/sign_language/screens/sign_language_screen.dart`
- Create: `lib/features/sign_language/screens/text_to_sign_screen.dart`
- Create: `lib/features/sign_language/bindings/sign_language_binding.dart`
- Create: `test/features/sign_language/screens/screens_integration_test.dart`

**Interfaces:**
- Consumes: Semua Controller, Services, dan Widgets dari Task 1–8
- Produces:
  - `SignLanguageScreen`: Layar utama Sign-to-Speech (Pratinjau Kamera + Glassmorphic HUD + Hold Ring + Kartu Transkrip AI + Tombol Spasi Ejaan & Reset)
  - `TextToSignScreen`: Layar utama Speech-to-Sign (SignSpeechCard + Pemutar Video Playlist Sekuensial + Tombol Unduh Kategori Offline)
  - `SignLanguageBinding`: Dependency Injection GetX untuk modul Sign-to-Speech

- [ ] **Step 1: Write failing integration test for Screens & Bindings**
  - Uji navigasi dan inisialisasi controller melalui `SignLanguageBinding` dan `TextToSignBinding`.
  - Verifikasi bahwa `SignLanguageScreen` dan `TextToSignScreen` merender komponen tanpa error overflow atau missing dependency.

- [ ] **Step 2: Run test to verify it fails**
  - Command: `flutter test test/features/sign_language/screens/screens_integration_test.dart`
  - Expected: FAIL

- [ ] **Step 3: Implement Screens and Bindings**
  - Bangun `SignLanguageScreen` dengan layout responsif adaptif (HUD di atas kamera, touch target $\ge 48\text{ dp}$).
  - Bangun `TextToSignScreen` dengan tata letak pemutar video di bagian atas dan area mikrofon di bagian bawah.
  - Konfigurasikan seluruh dependency injection di `SignLanguageBinding` dan `TextToSignBinding`.

- [ ] **Step 4: Run test to verify it passes**
  - Command: `flutter test test/features/sign_language/screens/screens_integration_test.dart`
  - Expected: PASS

- [ ] **Step 5: Commit changes**
  - Command: `git add lib/features/sign_language/screens/ lib/features/sign_language/bindings/ test/features/sign_language/screens/ && git commit -m "feat(screens): integrate SignLanguageScreen and TextToSignScreen with GetX bindings"`
