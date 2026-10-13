import 'package:flutter/foundation.dart';

class BisindoCandidate {
  final String label;
  final double confidence;

  const BisindoCandidate({
    required this.label,
    required this.confidence,
  });

  @override
  String toString() => 'BisindoCandidate($label, ${(confidence * 100).toStringAsFixed(1)}%)';
}

@immutable
class BisindoPrediction {
  final String label;
  final double confidence;
  final double margin;
  final bool isLetter;
  final List<BisindoCandidate> candidates;

  const BisindoPrediction({
    required this.label,
    required this.confidence,
    required this.margin,
    required this.isLetter,
    this.candidates = const [],
  });

  bool get isRecognized => label.isNotEmpty && confidence >= 0.50;

  /// Checks whether a label represents a single alphabetical letter
  static bool isLabelLetter(String label) {
    if (label.startsWith('LETTER_')) return true;
    final trimmed = label.trim();
    return trimmed.length == 1 && RegExp(r'^[A-Za-z]$').hasMatch(trimmed);
  }

  /// Extracts human readable clean label from raw label like WORD_HALO -> Halo or LETTER_A -> A
  String get cleanLabel {
    if (label.startsWith('WORD_')) {
      final raw = label.substring(5).toLowerCase();
      if (raw.isEmpty) return '';
      return raw[0].toUpperCase() + raw.substring(1);
    } else if (label.startsWith('LETTER_')) {
      return label.substring(7).toUpperCase();
    }
    if (label.isEmpty) return '';
    if (label.length == 1) return label.toUpperCase();
    return label[0].toUpperCase() + label.substring(1).toLowerCase();
  }

  @override
  String toString() =>
      'BisindoPrediction(label: $label, conf: ${confidence.toStringAsFixed(2)}, margin: ${margin.toStringAsFixed(2)}, isLetter: $isLetter)';
}
