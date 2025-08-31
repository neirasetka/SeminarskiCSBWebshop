class EnvironmentConfig {
  EnvironmentConfig._();

  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com');
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);
}

