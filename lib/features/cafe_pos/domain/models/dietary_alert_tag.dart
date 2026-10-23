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
}
