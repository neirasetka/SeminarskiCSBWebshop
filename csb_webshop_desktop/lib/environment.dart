class EnvironmentConfig {
  EnvironmentConfig._();

  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  static const String apiBaseUrl = String.fromEnvironment(
    'baseUrl',
    defaultValue: String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:5265'),
  );
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', defaultValue: '');
}

