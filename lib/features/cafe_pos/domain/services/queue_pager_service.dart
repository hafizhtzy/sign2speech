import 'package:flutter/services.dart';
import 'package:speech2sign/features/sign_language/services/bisindo_tts_service.dart';

class QueueCallEvent {
  final String queueNumber;
  final String customerName;
  final String speechText;
  final String signVideoKeyword;
  final bool isHearingTarget;
  final DateTime timestamp;

  const QueueCallEvent({
    required this.queueNumber,
    required this.customerName,
    required this.speechText,
    this.signVideoKeyword = 'PESANAN SIAP DIAMBIL',
    required this.isHearingTarget,
    required this.timestamp,
  });
}

class QueuePagerService {
  final BisindoTtsService? ttsService;

  QueuePagerService({this.ttsService});

  BisindoTtsService? get _ttsService => ttsService;

  /// Converts a number from 1 to 999 into Indonesian words.
  static String numberToIndonesianWords(int number) {
    if (number <= 0) return '$number';
    if (number > 999) return '$number';

    final satuan = [
      '',
      'satu',
      'dua',
      'tiga',
      'empat',
      'lima',
      'enam',
      'tujuh',
      'delapan',
      'sembilan',
      'sepuluh',
      'sebelas',
    ];

    if (number < 12) {
      return satuan[number];
    } else if (number < 20) {
      return '${satuan[number - 10]} belas';
    } else if (number < 100) {
      final puluh = number ~/ 10;
      final sisa = number % 10;
      return '${satuan[puluh]} puluh${sisa > 0 ? " ${satuan[sisa]}" : ""}';
    } else {
      final ratus = number ~/ 100;
      final sisa = number % 100;
      final prefix = ratus == 1 ? 'seratus' : '${satuan[ratus]} ratus';
      if (sisa == 0) return prefix;
      return '$prefix ${numberToIndonesianWords(sisa)}';
    }
  }

  /// Formats queue number (e.g., "A-108" -> "A seratus delapan", "B-12" -> "B dua belas").
  static String formatQueueNumberForSpeech(String queueNumber) {
    final clean = queueNumber.trim().toUpperCase();
    final parts = clean.split(RegExp(r'[-\s]'));
    if (parts.length == 2) {
      final letter = parts[0];
      final numVal = int.tryParse(parts[1]);
      if (numVal != null) {
        return '$letter ${numberToIndonesianWords(numVal)}';
      }
    } else {
      final numVal = int.tryParse(clean);
      if (numVal != null) {
        return numberToIndonesianWords(numVal);
      }
    }
    return clean;
  }

  /// Generates the announcement text in Indonesian.
  String generateHearingCallText({
    required String queueNumber,
    required String customerName,
    String pickupLocation = 'meja bar',
  }) {
    final formattedQueue = formatQueueNumberForSpeech(queueNumber);
    final trimmedName = customerName.trim();
    if (trimmedName.isNotEmpty) {
      return 'Pesanan nomor $formattedQueue atas nama $trimmedName sudah siap diambil di $pickupLocation. Terima kasih.';
    } else {
      return 'Pesanan nomor $formattedQueue sudah siap diambil di $pickupLocation. Terima kasih.';
    }
  }

  /// Dispatches call for a hearing customer via serial FIFO TTS.
  Future<QueueCallEvent> callHearingCustomer({
    required String queueNumber,
    required String customerName,
    String pickupLocation = 'meja bar',
    BisindoTtsService? ttsServiceOverride,
  }) async {
    final speechText = generateHearingCallText(
      queueNumber: queueNumber,
      customerName: customerName,
      pickupLocation: pickupLocation,
    );

    final tts = ttsServiceOverride ?? _ttsService;
    if (tts != null) {
      await tts.speak(speechText, languageCode: 'id-ID');
    }

    return QueueCallEvent(
      queueNumber: queueNumber,
      customerName: customerName,
      speechText: speechText,
      isHearingTarget: true,
      timestamp: DateTime.now(),
    );
  }

  /// Dispatches call for a Deaf customer triggering visual flash, haptic, and sign video playlist.
  Future<QueueCallEvent> callDeafCustomer({
    required String queueNumber,
    required String customerName,
    bool triggerHaptics = true,
  }) async {
    if (triggerHaptics) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {
        // Ignored on non-mobile platforms/tests
      }
    }

    return QueueCallEvent(
      queueNumber: queueNumber,
      customerName: customerName,
      speechText: 'Pesanan $queueNumber ($customerName) siap diambil',
      signVideoKeyword: 'PESANAN SIAP DIAMBIL',
      isHearingTarget: false,
      timestamp: DateTime.now(),
    );
  }
}
