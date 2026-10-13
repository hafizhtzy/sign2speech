import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../translator/services/speech_service.dart';
import '../models/sign_search_result.dart';
import '../models/sign_video_entry.dart';
import '../services/sign_language_asset_registry.dart';
import '../services/sign_language_cache_service.dart';
import '../services/sign_language_repository.dart';

/// Metadata paket kategori yang dihitung secara dinamis
class CategoryPackageInfo {
  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
  final int totalCount;
  final int remoteCount;

  const CategoryPackageInfo({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.totalCount,
    required this.remoteCount,
  });

  bool get isAllDownloaded => remoteCount == 0;
  bool get isFullyDownloaded => remoteCount == 0;
}

/// Controller GetX untuk fitur Text and Speech to Sign Language (SIBI & BISINDO).
class TextToSignController extends GetxController {
  final SignLanguageRepository _repository;
  SpeechService? _speechService;

  SpeechService get speechService =>
      _speechService ??= (Get.isRegistered<SpeechService>()
          ? Get.find<SpeechService>()
          : SpeechService());

  final TextEditingController textController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // ── REAKTIF STATE ─────────────────────────────────────────────────────────
  final RxString selectedLanguage = 'bisindo'.obs; // 'bisindo' atau 'sibi'
  final RxString currentQuery = ''.obs;
  String _lastSearchedQuery = '';

  final Rx<SignSearchResult?> searchResult = Rx<SignSearchResult?>(null);
  final Rx<SignVideoEntry?> currentEntry = Rx<SignVideoEntry?>(null);
  final RxList<SignVideoEntry> availableVideos = <SignVideoEntry>[].obs;

  // ── AUTOCOMPLETE SUGGESTIONS STATE ────────────────────────────────────────
  final RxList<String> searchSuggestions = <String>[].obs;
  final RxBool showSuggestions = false.obs;

  /// Kamus kosakata umum SIBI untuk auto-suggest
  static const List<String> sibiDictionary = [
    'Aku',
    'Bantu',
    'Beli',
    'Dia',
    'Dokter',
    'Haus',
    'Hilang',
    'Kami',
    'Kamu',
    'Lapar',
    'Lelah',
    'Makan',
    'Mana',
    'Masjid',
    'Minum',
    'Obat',
    'Sakit',
    'Segera',
    'Sesat',
    'Tolong bantu saya',
    'Rumah Sakit',
    'Ambulans',
    'Air Minum',
    'Tawaf',
    'Sa\'i',
    'Hotel',
    'Maktab',
    'Kloter',
    'Polisi',
    'Darurat',
    'Kamar Mandi',
  ];

  /// Kamus alfabet dan kosakata BISINDO untuk auto-suggest
  static const List<String> bisindoDictionary = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'Air',
    'Apa',
    'Apa Kabar',
    'Baik',
    'Berapa',
    'Berdiri',
    'Dia',
    'Dimana',
    'Duduk',
    'Halo',
    'Kalian',
    'Kami',
    'Kamu',
    'Kapan',
    'Kemana',
    'Kita',
    'Kopi',
    'Mandi',
    'Minum',
    'Siapa',
    'Terima Kasih',
    'Tuli',
  ];

  final RxBool isLoadingVideos = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isDownloading = false.obs;
  final RxDouble downloadProgress = 0.0.obs;

  final RxString statusMessage = ''.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);

  // ── VIDEO PLAYER STATE ───────────────────────────────────────────────────
  /// Jika `false` (default), pemutaran ditangani widget [SignVideoPlayer]
  /// lewat [currentVideoSource] sehingga hanya ada satu decoder aktif.
  final bool useInternalPlayer;
  VideoPlayerController? _playerController;
  VideoPlayerController? get playerController => _playerController;

  String? _activePlayingVideoId;
  String? get activePlayingVideoId => _activePlayingVideoId;
  final RxInt playSessionId = 0.obs;
  int get _playSessionId => playSessionId.value;

  final RxBool isVideoInitialized = false.obs;
  final RxBool isVideoPlaying = false.obs;
  final Rx<Duration> videoPosition = Duration.zero.obs;
  final Rx<Duration> videoDuration = Duration.zero.obs;

  // ── SEQUENTIAL PLAYLIST (KOMPATIBILITAS RESULT SCREEN) ────────────────────
  final RxList<SignVideoEntry> playlist = <SignVideoEntry>[].obs;
  final RxInt activeWordIndex = 0.obs;
  final RxBool isLooping = true.obs;
  final RxDouble playbackSpeed = 1.0.obs;
  final RxString currentVideoSource = ''.obs;
  final RxBool isLoadingVideo = false.obs;

  // ── CATEGORY PACKAGE DOWNLOAD STATE ──────────────────────────────────────
  final RxMap<String, double> categoryDownloadProgress = <String, double>{}.obs;
  final RxMap<String, bool> categoryDownloading = <String, bool>{}.obs;
  final Map<String, CancelToken> _categoryCancelTokens = {};

  // ── SPEECH-TO-SIGN STATE ─────────────────────────────────────────────────
  final RxBool isListening = false.obs;
  final RxString recognizedWords = ''.obs;
  final RxString speechStatusMessage = 'Tekan mikrofon & bicara kata/huruf'.obs;

  // ── PAGINASI KOSAKATA (5 PER HALAMAN) ────────────────────────────────────
  static const int vocabPageSize = 5;
  final RxInt currentVocabPage = 1.obs;

  TextToSignController({
    SpeechService? speechService,
    SignLanguageRepository? repository,
    this.useInternalPlayer = false,
  }) : _repository = repository ?? SignLanguageRepository.instance {
    if (speechService != null) {
      _speechService = speechService;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadAvailableVideos();
  }

  @override
  void onClose() {
    _disposePlayer();
    _speechService?.stopListening();
    textController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  // ── 1. PEMUATAN VIDEO & KATALOG ──────────────────────────────────────────

  /// Memuat daftar video yang tersedia untuk bahasa aktif.
  Future<void> loadAvailableVideos({bool forceRefresh = false}) async {
    try {
      isLoadingVideos.value = true;
      errorMessage.value = null;

      final videos = await _repository.getAvailableVideos(
        language: selectedLanguage.value,
        forceRefresh: forceRefresh,
      );

      availableVideos.assignAll(videos);
      currentVocabPage.value = 1;
    } catch (e) {
      debugPrint('[TextToSignCtrl] loadAvailableVideos error: $e');
      errorMessage.value = 'Gagal memuat katalog video: $e';
    } finally {
      isLoadingVideos.value = false;
    }
  }

  /// Beralih bahasa ('sibi' atau 'bisindo').
  void setLanguage(String language) {
    if (selectedLanguage.value == language) return;
    selectedLanguage.value = language;
    _lastSearchedQuery = '';
    _disposePlayer();
    currentEntry.value = null;
    searchResult.value = null;
    playlist.clear();
    currentVocabPage.value = 1;
    loadAvailableVideos();

    if (textController.text.trim().isNotEmpty) {
      searchSign(textController.text, force: true);
    }
  }

  // ── 2. AUTOCOMPLETE & TEXT-TO-SIGN SEARCH ─────────────────────────────────

  /// Memperbarui query pencarian dan memfilter saran kosakata (autocomplete).
  void updateSearchQuery(String text) {
    currentQuery.value = text;
    currentVocabPage.value = 1;
    final clean = text.trim().toLowerCase();

    if (clean.isEmpty) {
      searchSuggestions.clear();
      showSuggestions.value = false;
      return;
    }

    final candidatePool = <String>{};

    if (selectedLanguage.value == 'sibi') {
      candidatePool.addAll(sibiDictionary);
    } else {
      candidatePool.addAll(bisindoDictionary);
    }

    for (final v in availableVideos) {
      candidatePool.add(v.label);
    }

    for (final b in SignLanguageAssetRegistry.defaultOfflineAssets) {
      final name = b.split('/').last.replaceAll('.mp4', '').replaceAll('_', ' ');
      candidatePool.add(name);
    }

    final prefixMatches = <String>[];
    final containsMatches = <String>[];

    for (final item in candidatePool) {
      final itemLower = item.toLowerCase();
      if (itemLower.startsWith(clean)) {
        prefixMatches.add(item);
      } else if (itemLower.contains(clean)) {
        containsMatches.add(item);
      }
    }

    prefixMatches.sort((a, b) => a.length.compareTo(b.length));
    containsMatches.sort((a, b) => a.length.compareTo(b.length));

    final combined = [...prefixMatches, ...containsMatches].take(6).toList();

    searchSuggestions.assignAll(combined);
    showSuggestions.value = !isListening.value && combined.isNotEmpty;
  }

  /// Memilih salah satu saran autocomplete, mengisi input, dan langsung memicu pemutaran video.
  void selectSuggestion(String suggestion) {
    textController.text = suggestion;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    currentQuery.value = suggestion;
    currentVocabPage.value = 1;
    showSuggestions.value = false;
    searchSuggestions.clear();
    searchFocusNode.unfocus();
    searchSign(suggestion, force: true);
  }

  void dismissSuggestions() {
    showSuggestions.value = false;
  }

  void clearSearch() {
    _lastSearchedQuery = '';
    textController.clear();
    currentQuery.value = '';
    currentVocabPage.value = 1;
    searchSuggestions.clear();
    showSuggestions.value = false;
    searchSign('');
  }

  /// Mencari dan mencocokkan teks ke video bahasa isyarat.
  Future<void> searchSign(String text, {bool force = false}) async {
    final query = text.trim();
    currentQuery.value = query;
    if (query.isEmpty) {
      _lastSearchedQuery = '';
      searchResult.value = null;
      currentEntry.value = null;
      playlist.clear();
      _disposePlayer();
      return;
    }

    if (!force &&
        query.toLowerCase() == _lastSearchedQuery.toLowerCase() &&
        (isSearching.value || searchResult.value != null)) {
      return;
    }

    _lastSearchedQuery = query;

    try {
      isSearching.value = true;
      isLoadingVideo.value = true;
      errorMessage.value = null;

      final result = await _repository.searchSign(
        query,
        selectedLanguage.value,
      );

      searchResult.value = result;

      if (result.isFound && result.matchedEntries.isNotEmpty) {
        playlist.assignAll(result.matchedEntries);
        activeWordIndex.value = 0;
        final entry = result.exactMatch ?? result.matchedEntries.first;
        currentEntry.value = entry;
        // autoDownload=false: video remote tampilkan tombol unduh, tidak langsung download
        await playEntry(entry, force: force, autoDownload: false);
        if (result.isCrossLanguageFallback) {
          final lang = result.crossLanguageSystem?.toUpperCase() ?? 'bahasa lain';
          statusMessage.value = 'Hasil dari $lang (tidak ada di ${selectedLanguage.value.toUpperCase()})';
        }
      } else {
        playlist.clear();
        currentEntry.value = null;
        statusMessage.value = 'Isyarat untuk "$query" belum ditemukan.';
        _disposePlayer();
      }
    } catch (e) {
      debugPrint('[TextToSignCtrl] searchSign error: $e');
      errorMessage.value = 'Terjadi kesalahan saat mencari video: $e';
    } finally {
      isSearching.value = false;
      isLoadingVideo.value = false;
    }
  }

  /// Alias pemrosesan input ucapan/suara untuk integrasi tombol layar Speech to Sign.
  Future<void> processVoiceInput(String query) async {
    recognizedWords.value = query;
    textController.text = query;
    await searchSign(query, force: true);
  }

  // ── 3. VIDEO PLAYBACK LIFECYCLE ──────────────────────────────────────────

  /// Memutar video berdasarkan status source (asset vs localCached vs remote).
  /// Jika remote, otomatis mengunduh ke storage lokal lalu memutarnya secara mulus.
  Future<void> playEntry(
    SignVideoEntry entry, {
    bool force = false,
    bool autoDownload = true,
  }) async {
    final currentSession = ++playSessionId.value;

    // Selesaikan status sumber aktual
    final resolved = await _repository.resolveVideoSource(entry);

    if (currentSession != _playSessionId) return;

    // Jika video yang sama sudah diinisialisasi dan aktif, lanjutkan pemutaran
    if (!force &&
        _playerController != null &&
        isVideoInitialized.value &&
        _activePlayingVideoId == resolved.id) {
      if (!isVideoPlaying.value) {
        await _playerController?.play();
      }
      return;
    }

    currentEntry.value = resolved;

    // Sinkronkan playlist jika entry belum ada di dalamnya
    if (playlist.isEmpty || !playlist.any((p) => p.id == resolved.id)) {
      playlist.assignAll([resolved]);
      activeWordIndex.value = 0;
    }

    // Jika video remote dan belum di-cache, otomatis unduh jika autoDownload aktif
    if (resolved.source == SignVideoSource.remote) {
      if (autoDownload) {
        await downloadAndPlay(resolved);
        return;
      } else {
        _disposePlayer();
        currentVideoSource.value = resolved.path;
        statusMessage.value =
            'Video "${resolved.label}" berada di cloud dan belum diunduh.';
        return;
      }
    }

    // Serahkan sumber lokal ke widget SignVideoPlayer (satu-satunya pemutar).
    _disposePlayer();
    errorMessage.value = null;
    currentVideoSource.value = resolved.path;
    statusMessage.value = resolved.source == SignVideoSource.asset
        ? 'Tersedia offline (Aset Bawaan)'
        : 'Tersedia offline (Tersimpan di Cache)';

    // Pemutar internal hanya dipakai jika layar tidak memakai SignVideoPlayer.
    if (!useInternalPlayer) return;

    try {

      final VideoPlayerController controller;
      if (resolved.source == SignVideoSource.asset) {
        controller = VideoPlayerController.asset(resolved.path);
      } else if (resolved.source == SignVideoSource.localCached &&
          resolved.cachedFilePath != null) {
        controller = VideoPlayerController.file(File(resolved.cachedFilePath!));
      } else if (resolved.cachedFilePath != null &&
          File(resolved.cachedFilePath!).existsSync()) {
        controller = VideoPlayerController.file(File(resolved.cachedFilePath!));
      } else {
        // Fallback network streaming jika offline cache belum selesai
        controller = VideoPlayerController.networkUrl(
          Uri.parse(resolved.remoteUrl),
        );
      }

      await controller.initialize();
      if (currentSession != _playSessionId) {
        controller.dispose();
        return;
      }

      controller.setLooping(isLooping.value);
      controller.setPlaybackSpeed(playbackSpeed.value);

      controller.addListener(_videoPlayerListener);

      _playerController = controller;
      _activePlayingVideoId = resolved.id;
      isVideoInitialized.value = true;
      videoDuration.value = controller.value.duration;

      await controller.play();
      isVideoPlaying.value = true;
      statusMessage.value = resolved.source == SignVideoSource.asset
          ? 'Tersedia offline (Aset Bawaan)'
          : 'Tersedia offline (Tersimpan di Cache)';
    } catch (e) {
      if (currentSession == _playSessionId) {
        debugPrint('[TextToSignCtrl] playEntry error: $e');
        errorMessage.value = 'Gagal memutar video: $e';
        _disposePlayer();
      }
    }
  }

  void _videoPlayerListener() {
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) return;

    videoPosition.value = controller.value.position;
    isVideoPlaying.value = controller.value.isPlaying;

    // Periksa apakah video selesai diputar pada mode playlist
    if (!isLooping.value &&
        controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      onVideoFinished();
    }
  }

  void togglePlayPause() {
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  Future<void> replay() async {
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) return;

    await controller.seekTo(Duration.zero);
    await controller.play();
  }

  Future<void> seekTo(Duration position) async {
    final controller = _playerController;
    if (controller == null || !controller.value.isInitialized) return;

    await controller.seekTo(position);
  }

  void _disposePlayer() {
    if (_playerController != null) {
      _playerController!.removeListener(_videoPlayerListener);
      _playerController!.dispose();
      _playerController = null;
    }
    _activePlayingVideoId = null;
    isVideoInitialized.value = false;
    isVideoPlaying.value = false;
    videoPosition.value = Duration.zero;
    videoDuration.value = Duration.zero;
  }

  // ── 4. DOWNLOAD VIDEO SINGLE & PLAY ──────────────────────────────────────

  /// Mengunduh video remote lalu otomatis memutarnya di player lokal.
  Future<void> downloadAndPlay(SignVideoEntry entry) async {
    if (isDownloading.value) return;

    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      errorMessage.value = null;
      // Kosongkan sumber lama agar badge & pemutar tidak menampilkan video sebelumnya.
      currentVideoSource.value = '';
      statusMessage.value = 'Mengunduh video (${entry.label})...';

      final downloadedEntry = await _repository.downloadVideo(
        entry,
        onProgress: (p) {
          downloadProgress.value = p;
        },
      );

      currentEntry.value = downloadedEntry;
      currentVideoSource.value = downloadedEntry.path;

      final index = availableVideos.indexWhere((v) => v.id == entry.id);
      if (index != -1) {
        availableVideos[index] = downloadedEntry;
      }

      final plIndex = playlist.indexWhere((v) => v.id == entry.id);
      if (plIndex != -1) {
        playlist[plIndex] = downloadedEntry;
      }

      if (downloadedEntry.source != SignVideoSource.localCached) {
        currentVideoSource.value = '';
        errorMessage.value =
            'Video belum berhasil diunduh. Periksa koneksi internet dan coba lagi.';
        return;
      }

      await playEntry(downloadedEntry, force: true, autoDownload: false);
    } on SignVideoNotAvailableException catch (e) {
      debugPrint('[TextToSignCtrl] downloadAndPlay: $e');
      currentVideoSource.value = '';
      final system = selectedLanguage.value.toUpperCase();
      errorMessage.value =
          'Video $system untuk "${entry.label}" belum tersedia di server.';
      statusMessage.value = errorMessage.value!;
    } catch (e) {
      debugPrint('[TextToSignCtrl] downloadAndPlay error: $e');
      currentVideoSource.value = '';
      errorMessage.value =
          'Video belum berhasil diunduh. Periksa koneksi internet dan coba lagi.';
    } finally {
      isDownloading.value = false;
      downloadProgress.value = 0.0;
    }
  }

  // ── 5. DOWNLOAD PAKET KATEGORI OFFLINE ────────────────────────────────────

  List<CategoryPackageInfo> get dynamicPackageCategories {
    final Map<String, List<SignVideoEntry>> grouped = {};
    for (final v in availableVideos) {
      grouped.putIfAbsent(v.category.toLowerCase().trim(), () => []).add(v);
    }

    final List<CategoryPackageInfo> list = [];
    grouped.forEach((category, videos) {
      final remoteCount = videos
          .where((v) => v.source == SignVideoSource.remote)
          .length;
      final totalCount = videos.length;

      list.add(
        CategoryPackageInfo(
          category: category,
          title: _getCategoryDisplayTitle(category),
          subtitle: _getCategoryDisplaySubtitle(videos),
          icon: _getCategoryDisplayIcon(category),
          totalCount: totalCount,
          remoteCount: remoteCount,
        ),
      );
    });

    list.sort((a, b) {
      if (a.remoteCount > 0 && b.remoteCount == 0) return -1;
      if (a.remoteCount == 0 && b.remoteCount > 0) return 1;
      return a.title.compareTo(b.title);
    });

    return list;
  }

  static String _getCategoryDisplayTitle(String cat) {
    switch (cat.toLowerCase().trim()) {
      case 'health':
      case 'kesehatan':
        return 'Paket Kesehatan';
      case 'hajj':
      case 'ibadah':
        return 'Paket Ibadah & Haji';
      case 'emergency':
      case 'darurat':
        return 'Paket Darurat';
      case 'alphabet':
      case 'alfabet':
        return 'Paket Alfabet';
      case 'question':
      case 'pertanyaan':
        return 'Paket Tanya Jawab';
      case 'pronoun':
        return 'Paket Kata Ganti';
      case 'movement':
        return 'Paket Gerakan';
      case 'activity':
      case 'harian':
        return 'Paket Aktivitas Harian';
      case 'greeting':
      case 'salam':
        return 'Paket Salam & Sapaan';
      case 'layanan_publik':
        return 'Paket Layanan Publik';
      default:
        return 'Paket ${cat.capitalizeFirst ?? cat.toUpperCase()}';
    }
  }

  static String _getCategoryDisplaySubtitle(List<SignVideoEntry> videos) {
    final sample = videos.map((v) => v.label).take(3).join(', ');
    if (videos.length > 3) {
      return '$sample, dsb. (${videos.length} video)';
    }
    return '$sample (${videos.length} video)';
  }

  static IconData _getCategoryDisplayIcon(String cat) {
    switch (cat.toLowerCase().trim()) {
      case 'health':
      case 'kesehatan':
        return Icons.local_hospital_rounded;
      case 'hajj':
      case 'ibadah':
        return Icons.mosque_rounded;
      case 'emergency':
      case 'darurat':
        return Icons.warning_amber_rounded;
      case 'alphabet':
      case 'alfabet':
        return Icons.spellcheck_rounded;
      case 'question':
      case 'pertanyaan':
        return Icons.help_outline_rounded;
      case 'pronoun':
        return Icons.people_outline_rounded;
      case 'movement':
        return Icons.accessibility_new_rounded;
      case 'activity':
      case 'harian':
        return Icons.directions_run_rounded;
      case 'greeting':
      case 'salam':
        return Icons.waving_hand_rounded;
      case 'layanan_publik':
        return Icons.room_service_rounded;
      default:
        return Icons.folder_special_rounded;
    }
  }

  Future<void> downloadCategoryPackage(String category) async {
    if (categoryDownloading[category] == true) return;

    final cancelToken = CancelToken();
    _categoryCancelTokens[category] = cancelToken;

    try {
      categoryDownloading[category] = true;
      categoryDownloadProgress[category] = 0.0;

      await _repository.downloadCategory(
        category,
        language: selectedLanguage.value,
        cancelToken: cancelToken,
        onProgress: (progress) {
          categoryDownloadProgress[category] = progress;
        },
      );

      await loadAvailableVideos();

      if (currentEntry.value != null &&
          currentEntry.value!.category.toLowerCase() ==
              category.toLowerCase()) {
        final reResolved = await _repository.resolveVideoSource(
          currentEntry.value!,
        );
        currentEntry.value = reResolved;
        if (reResolved.source == SignVideoSource.localCached &&
            !isVideoPlaying.value) {
          await playEntry(reResolved);
        }
      }

      Get.snackbar(
        'Unduhan Berhasil',
        'Paket ${_getCategoryDisplayTitle(category)} telah siap digunakan offline.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } catch (e) {
      if (cancelToken.isCancelled) {
        Get.snackbar(
          'Unduhan Dibatalkan',
          'Pengunduhan paket ${_getCategoryDisplayTitle(category)} telah dibatalkan.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
      } else {
        debugPrint('[TextToSignCtrl] downloadCategoryPackage error: $e');
        Get.snackbar(
          'Unduhan Terkendala',
          'Beberapa video paket gagal diunduh. Silakan coba kembali saat internet stabil.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
        );
      }
    } finally {
      categoryDownloading[category] = false;
      categoryDownloadProgress[category] = 1.0;
      _categoryCancelTokens.remove(category);
    }
  }

  void cancelCategoryPackageDownload(String category) {
    if (_categoryCancelTokens.containsKey(category)) {
      _categoryCancelTokens[category]?.cancel('Dibatalkan oleh pengguna');
      _categoryCancelTokens.remove(category);
    }
    categoryDownloading[category] = false;
    categoryDownloadProgress[category] = 0.0;
  }

  // ── 6. CACHE MANAGEMENT ──────────────────────────────────────────────────

  Future<void> clearDownloadedVideos() async {
    _disposePlayer();
    final count = await _repository.clearDownloadedVideos();
    await loadAvailableVideos();

    if (currentEntry.value != null) {
      final reResolved = await _repository.resolveVideoSource(
        currentEntry.value!,
      );
      currentEntry.value = reResolved;
      if (reResolved.source == SignVideoSource.remote) {
        _disposePlayer();
        statusMessage.value =
            'Video berada di cloud. Silakan unduh untuk memutar secara offline.';
      } else if (reResolved.source == SignVideoSource.asset) {
        await playEntry(reResolved);
      }
    }

    Get.snackbar(
      'Pembersihan Selesai',
      '$count video unduhan telah dihapus dari memori perangkat.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  Future<void> refreshCurrentEntrySource() async {
    if (currentEntry.value != null) {
      final resolved = await _repository.resolveVideoSource(
        currentEntry.value!,
      );
      currentEntry.value = resolved;
      if (resolved.source == SignVideoSource.remote &&
          isVideoInitialized.value) {
        _disposePlayer();
      }
    }
  }

  Future<void> selectVocabularyItem(SignVideoEntry video) async {
    _lastSearchedQuery = video.label;
    textController.text = video.label;
    currentQuery.value = video.label;
    currentEntry.value = video;
    playlist.assignAll([video]);
    activeWordIndex.value = 0;
    searchResult.value = SignSearchResult(
      query: video.label,
      language: selectedLanguage.value,
      exactMatch: video,
      candidates: [video],
      isFound: true,
    );
    await playEntry(video, force: true);
  }

  // ── 7. SPEECH-TO-SIGN (VOICE RECOGNITION) ──────────────────────────────────

  Future<void> toggleVoiceRecognition() async {
    final service = speechService;
    if (isListening.value) {
      await service.stopListening();
      isListening.value = false;
      showSuggestions.value = false;
      final text = textController.text.trim();
      if (text.isNotEmpty &&
          text.toLowerCase() != _lastSearchedQuery.toLowerCase()) {
        await searchSign(text);
      }
      return;
    }

    recognizedWords.value = '';
    speechStatusMessage.value = 'Mendengarkan... Silakan ucapkan kata';
    isListening.value = true;

    await service.startListening(
      languageCode: 'id_ID',
      onResult: (text, isFinal) {
        onSpeechResult(text, isFinal);
      },
    );
  }

  void onSpeechResult(String text, bool isFinal) {
    final cleanWords = text.trim();
    if (cleanWords.isNotEmpty) {
      recognizedWords.value = cleanWords;
      textController.text = cleanWords;
      textController.selection = TextSelection.fromPosition(
        TextPosition(offset: cleanWords.length),
      );
      currentQuery.value = cleanWords;
      updateSearchQuery(cleanWords);
      if (isFinal) {
        isListening.value = false;
        showSuggestions.value = false;
        speechStatusMessage.value = 'Terdeteksi: "$cleanWords"';
        searchSign(cleanWords);
        speechService.stopListening();
      }
    }
  }

  Future<void> stopVoiceRecognition() async {
    if (isListening.value) {
      await speechService.stopListening();
      isListening.value = false;
      showSuggestions.value = false;
      final text = textController.text.trim();
      if (text.isNotEmpty &&
          text.toLowerCase() != _lastSearchedQuery.toLowerCase()) {
        await searchSign(text);
      }
    }
  }

  // ── 8. PAGINASI KOSAKATA (5 PER HALAMAN) ──────────────────────────────────

  List<SignVideoEntry> get filteredVocabulary {
    final query = currentQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return availableVideos;
    }
    return availableVideos.where((v) {
      final labelMatch = v.label.toLowerCase().contains(query);
      final aliasMatch = v.aliases.any((a) => a.toLowerCase().contains(query));
      final catMatch = v.category.toLowerCase().contains(query);
      return labelMatch || aliasMatch || catMatch;
    }).toList();
  }

  int get totalVocabPages {
    final list = filteredVocabulary;
    if (list.isEmpty) return 1;
    return ((list.length - 1) / vocabPageSize).floor() + 1;
  }

  List<SignVideoEntry> get paginatedVocabulary {
    final list = filteredVocabulary;
    if (list.isEmpty) return [];
    final total = totalVocabPages;
    final page = currentVocabPage.value.clamp(1, total);
    final start = (page - 1) * vocabPageSize;
    final end = (start + vocabPageSize).clamp(0, list.length);
    if (start >= list.length) {
      return list.take(vocabPageSize).toList();
    }
    return list.sublist(start, end);
  }

  void nextVocabPage() {
    if (currentVocabPage.value < totalVocabPages) {
      currentVocabPage.value++;
    }
  }

  void previousVocabPage() {
    if (currentVocabPage.value > 1) {
      currentVocabPage.value--;
    }
  }

  void goToVocabPage(int page) {
    if (page >= 1 && page <= totalVocabPages) {
      currentVocabPage.value = page;
    }
  }

  // ── 9. PLAYLIST CONTROLS (KOMPATIBILITAS SEKUENSIS KATA) ───────────────────

  void onVideoFinished() {
    if (playlist.isEmpty) return;

    if (activeWordIndex.value + 1 < playlist.length) {
      activeWordIndex.value++;
      playEntry(playlist[activeWordIndex.value]);
    } else if (isLooping.value) {
      activeWordIndex.value = 0;
      playEntry(playlist[0]);
    }
  }

  void selectWordIndex(int index) {
    if (index >= 0 && index < playlist.length) {
      activeWordIndex.value = index;
      playEntry(playlist[index]);
    }
  }

  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
    _playerController?.setPlaybackSpeed(speed);
  }

  void toggleLooping() {
    isLooping.value = !isLooping.value;
    _playerController?.setLooping(isLooping.value);
  }
}
