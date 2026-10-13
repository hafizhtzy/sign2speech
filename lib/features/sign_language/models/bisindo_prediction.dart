import 'package:flutter/foundation.dart';

@immutable
class BisindoPrediction {
  final String label;
  final double confidence;
  final double margin;
  final bool isLetter;

  const BisindoPrediction({
    required this.label,
    required this.confidence,
    required this.margin,
    required this.isLetter,
  });

  /// Extracts human readable clean label from raw label like WORD_HALO -> Halo or LETTER_A -> A
  String get cleanLabel {
    if (label.startsWith('WORD_')) {
      final raw = label.substring(5).toLowerCase();
      if (raw.isEmpty) return '';
      return raw[0].toUpperCase() + raw.substring(1);
    } else if (label.startsWith('LETTER_')) {
      return label.substring(7).toUpperCase();
    }
    return label;
  }

  @override
  String toString() =>
      'BisindoPrediction(label: $label, conf: ${confidence.toStringAsFixed(2)}, margin: ${margin.toStringAsFixed(2)}, isLetter: $isLetter)';
}
