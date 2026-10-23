enum DietaryAlertSeverity {
  info,
  warning,
  critical,
}

enum DietaryAlertType {
  lactoseIntolerant,
  diabetesSugarAlert,
  nutAllergy,
  dairyAllergy,
  acidRefluxMaag,
}

class DietaryAlertTag {
  final DietaryAlertType type;
  final DietaryAlertSeverity severity;
  final String labelKey;
  final String defaultMessageId;
  final String defaultMessageEn;
  final String detectedKeyword;

  const DietaryAlertTag({
    required this.type,
    required this.severity,
    required this.labelKey,
    required this.defaultMessageId,
    required this.defaultMessageEn,
    required this.detectedKeyword,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietaryAlertTag &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          detectedKeyword == other.detectedKeyword;

  @override
  int get hashCode => type.hashCode ^ detectedKeyword.hashCode;

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
      'labelKey': labelKey,
      'defaultMessageId': defaultMessageId,
      'defaultMessageEn': defaultMessageEn,
      'detectedKeyword': detectedKeyword,
    };
  }

  factory DietaryAlertTag.fromMap(Map<String, dynamic> map) {
    return DietaryAlertTag(
      type: DietaryAlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DietaryAlertType.lactoseIntolerant,
      ),
      severity: DietaryAlertSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => DietaryAlertSeverity.info,
      ),
      labelKey: map['labelKey'] as String? ?? '',
      defaultMessageId: map['defaultMessageId'] as String? ?? '',
      defaultMessageEn: map['defaultMessageEn'] as String? ?? '',
      detectedKeyword: map['detectedKeyword'] as String? ?? '',
    );
  }
}

