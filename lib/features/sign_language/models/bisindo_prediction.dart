import 'package:flutter/foundation.dart';

enum BisindoMatchQuality { strong, possible, unknown }

class BisindoCandidate {
  final int classId;
  final String label;
  final double distance;
  final double confidence;

  const BisindoCandidate({
    this.classId = -1,
    required this.label,
    this.distance = 0.0,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'label': label,
        'distance': distance,
        'confidence': confidence,
      };

  @override
  String toString() =>
      'BisindoCandidate($label, ${(confidence * 100).toStringAsFixed(1)}%, dist: ${distance.toStringAsFixed(3)})';
}

@immutable
class BisindoPrediction {
  final int classId;
  final String label;
  final double confidence;
  final double distance;
  final double margin;
  final bool isLetter;
  final bool isRecognized;
  final String? guidance;
  final BisindoMatchQuality matchQuality;
  final List<BisindoCandidate> candidates;

  const BisindoPrediction({
    this.classId = -1,
    required this.label,
    required this.confidence,
    this.distance = 0.0,
    this.margin = 0.0,
    this.isLetter = false,
    this.isRecognized = true,
    this.guidance,
    this.matchQuality = BisindoMatchQuality.possible,
    this.candidates = const [],
  });

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

  BisindoPrediction copyWith({
    int? classId,
    String? label,
    double? confidence,
    double? distance,
    double? margin,
    bool? isLetter,
    bool? isRecognized,
    String? guidance,
    BisindoMatchQuality? matchQuality,
    List<BisindoCandidate>? candidates,
  }) {
    return BisindoPrediction(
      classId: classId ?? this.classId,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      distance: distance ?? this.distance,
      margin: margin ?? this.margin,
      isLetter: isLetter ?? this.isLetter,
      isRecognized: isRecognized ?? this.isRecognized,
      guidance: guidance ?? this.guidance,
      matchQuality: matchQuality ?? this.matchQuality,
      candidates: candidates ?? this.candidates,
    );
  }

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'label': label,
        'confidence': confidence,
        'distance': distance,
        'isRecognized': isRecognized,
        'guidance': guidance,
        'margin': margin,
        'matchQuality': matchQuality.name,
        'candidates': candidates.map((c) => c.toJson()).toList(),
      };

  @override
  String toString() =>
      'BisindoPrediction(label: "$label", conf: ${(confidence * 100).toStringAsFixed(1)}%, margin: ${(margin * 100).toStringAsFixed(1)}%, dist: ${distance.toStringAsFixed(3)})';
}
