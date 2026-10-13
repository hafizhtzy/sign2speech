import 'package:flutter/foundation.dart';

@immutable
class SignLanguageConfig {
  static const String defaultBaseUrl = 'https://hajicare-sign.web.app';
  static const String catalogUrl = '$defaultBaseUrl/index.json';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  final String baseUrl;

  const SignLanguageConfig({this.baseUrl = defaultBaseUrl});

  String buildVideoUrl({required String language, required String slug}) {
    return '$baseUrl/videos/$language/${slug}_v1.mp4';
  }

  static String resolveVideoUrl(String relativePath, {String baseUrl = defaultBaseUrl}) {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    final cleanPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return '$baseUrl/$cleanPath';
  }
}

