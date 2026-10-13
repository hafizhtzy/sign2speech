import '../services/bisindo_classifier_service.dart';

/// Supported Sign Language models in the system.
enum SignLanguageModel {
  sibi,
  bisindo,
}

class SignLanguageModelConfig {
  final String modelName;
  final int classCount;
  final double defaultConfidenceThreshold;
  final double minMargin;

  const SignLanguageModelConfig({
    required this.modelName,
    required this.classCount,
    this.defaultConfidenceThreshold = 0.70,
    this.minMargin = 0.15,
  });

  static SignLanguageModelConfig forModel(SignLanguageModel model) {
    switch (model) {
      case SignLanguageModel.bisindo:
        return const SignLanguageModelConfig(
          modelName: 'BISINDO',
          classCount: 47,
          defaultConfidenceThreshold: 0.70,
          minMargin: 0.15,
        );
      case SignLanguageModel.sibi:
        return const SignLanguageModelConfig(
          modelName: 'SIBI',
          classCount: 72,
          defaultConfidenceThreshold: 0.70,
          minMargin: 0.15,
        );
    }
  }
}

extension SignLanguageModelExt on SignLanguageModel {
  String get displayName => this == SignLanguageModel.sibi ? 'SIBI' : 'BISINDO';
  int get classCount => this == SignLanguageModel.sibi ? 72 : 47;
  SignLanguageModelConfig get config => SignLanguageModelConfig.forModel(this);

  SignLanguageModelType get toModelType =>
      this == SignLanguageModel.sibi
          ? SignLanguageModelType.sibi
          : SignLanguageModelType.bisindo;
}
