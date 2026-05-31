class EnvironmentConfig {
  EnvironmentConfig._();

  static const String flavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  /// API root (bez /api sufiksa — putanje u ApiClient već počinju s /api/...).
  /// Docker (default): http://localhost:8080
  /// Visual Studio (Kestrel http profil): --dart-define=baseUrl=http://localhost:5265
  static const String apiBaseUrl = String.fromEnvironment(
    'baseUrl',
    defaultValue: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
  );

  static const bool enableLogging =
      bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51T6hBZCTVgVOvGUsDwWQGj588wzdirVATXce19ah3iMUzjeElXoetFCZTVAwbrMhgMuSmCoPFzhIP5xsfGEL4tDP00sa9PWkct',
  );
}
