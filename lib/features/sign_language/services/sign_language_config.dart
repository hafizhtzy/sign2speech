import 'package:flutter/foundation.dart';

@immutable
class SignLanguageConfig {
  final String baseUrl;

  const SignLanguageConfig({this.baseUrl = 'https://hajicare-sign.web.app'});

  String buildVideoUrl({required String language, required String slug}) {
    return '$baseUrl/videos/$language/${slug}_v1.mp4';
  }
}
