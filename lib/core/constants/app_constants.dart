class AppConstants {
  AppConstants._();

  /// Primary Firebase Hosting Project ID
  static const String signHostingProjectId = 'sign-language-c5d23';

  /// Primary Firebase Hosting Base URL for Sign Language videos and assets
  static const String signBaseUrl = 'https://sign-language-c5d23.web.app';

  /// Alternative Firebase Hosting Base URL
  static const String signAltBaseUrl = 'https://sign-language-c5d23.firebaseapp.com';

  /// Remote endpoint for the official video catalog JSON
  static const String signCatalogUrl = '$signBaseUrl/catalog.json';

  /// Bundled local asset path for the official catalog JSON
  static const String signCatalogAssetPath = 'assets/sign_language/catalog.json';

  /// Hosting domain name for display purposes
  static const String signHostingDomain = 'sign-language-c5d23.web.app';
}
