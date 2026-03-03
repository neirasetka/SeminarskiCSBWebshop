class EnvironmentConfig {
  EnvironmentConfig._();

  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  /// Konfigurabilna base URL. Postavi s: --dart-define=baseUrl=http://192.168.1.1:5265
  static const String baseUrl = String.fromEnvironment(
    'baseUrl',
    defaultValue: 'http://localhost:5265',
  );

  /// Alias za kompatibilnost
  static const String apiBaseUrl = baseUrl;
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51T6hBZCTVgVOvGUsDwWQGj588wzdirVATXce19ah3iMUzjeElXoetFCZTVAwbrMhgMuSmCoPFzhIP5xsfGEL4tDP00sa9PWkct',
  );
}

