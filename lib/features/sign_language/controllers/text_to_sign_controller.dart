import 'package:get/get.dart';

import '../models/sign_video_entry.dart';
import '../services/sign_language_repository.dart';
import '../../translator/services/speech_service.dart';

class TextToSignController extends GetxController {
  final SpeechService speechService;
  final SignLanguageRepository repository;

  final RxBool isListening = false.obs;
  final RxString recognizedWords = ''.obs;
  final RxList<SignVideoEntry> playlist = <SignVideoEntry>[].obs;
  final RxInt activeWordIndex = 0.obs;
  final RxInt playSessionId = 0.obs;
  final RxBool isLooping = true.obs;
  final RxDouble playbackSpeed = 1.0.obs;
  final RxString currentVideoSource = ''.obs;
  final RxBool isLoadingVideo = false.obs;
  final RxString statusMessage = 'Tekan mikrofon untuk mulai berbicara'.obs;

  TextToSignController({required this.speechService, required this.repository});

  @override
  void onClose() {
    speechService.stopListening();
    super.onClose();
  }

  Future<void> toggleVoiceRecognition() async {
    if (isListening.value) {
      await speechService.stopListening();
      isListening.value = false;
      statusMessage.value = 'Mendengarkan berhenti';
    } else {
      isListening.value = true;
      recognizedWords.value = '';
      statusMessage.value = 'Mendengarkan...';
      await speechService.startListening(
        languageCode: 'id_ID',
        onResult: (text, isFinal) {
          onSpeechResult(text, isFinal);
        },
      );
    }
  }

  void onSpeechResult(String text, bool isFinal) {
    recognizedWords.value = text;
    if (isFinal) {
      isListening.value = false;
      speechService.stopListening();
      processVoiceInput(text);
    }
  }

  Future<void> processVoiceInput(String query) async {
    final currentSession = ++playSessionId.value;
    statusMessage.value = 'Mencari peragaan isyarat...';
    isLoadingVideo.value = true;

    final result = await repository.searchSign(query, 'bisindo');

    // Reject stale session if another input arrived while searching
    if (currentSession != playSessionId.value) return;

    if (result.hasMatch) {
      playlist.assignAll(result.matchedEntries);
      activeWordIndex.value = 0;
      statusMessage.value = 'Memutar isyarat';
      await _loadVideoForActiveIndex(currentSession);
    } else {
      playlist.clear();
      statusMessage.value = 'Isyarat belum tersedia di perpustakaan';
      isLoadingVideo.value = false;
    }
  }

  Future<void> _loadVideoForActiveIndex(int session) async {
    if (playlist.isEmpty || activeWordIndex.value >= playlist.length) {
      isLoadingVideo.value = false;
      return;
    }

    final entry = playlist[activeWordIndex.value];
    final source = await repository.resolveVideoSource(entry);

    if (session == playSessionId.value) {
      currentVideoSource.value = source;
      isLoadingVideo.value = false;
    }
  }

  void onVideoFinished() {
    if (playlist.isEmpty) return;

    if (activeWordIndex.value + 1 < playlist.length) {
      activeWordIndex.value++;
      _loadVideoForActiveIndex(playSessionId.value);
    } else if (isLooping.value) {
      activeWordIndex.value = 0;
      _loadVideoForActiveIndex(playSessionId.value);
    }
  }

  void selectWordIndex(int index) {
    if (index >= 0 && index < playlist.length) {
      activeWordIndex.value = index;
      _loadVideoForActiveIndex(playSessionId.value);
    }
  }

  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
  }

  void toggleLooping() {
    isLooping.value = !isLooping.value;
  }
}
