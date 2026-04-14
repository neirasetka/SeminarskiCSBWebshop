import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  EnvironmentConfig._();

  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  /// Konfigurabilna base URL. Postavi s: --dart-define=baseUrl=http://192.168.1.1:5265
  static const String _baseUrlOverride = String.fromEnvironment(
    'baseUrl',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }

    if (kIsWeb) {
      return 'http://localhost:5265';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator reaches host machine through 10.0.2.2.
        return 'http://10.0.2.2:5265';
      default:
        return 'http://localhost:5265';
    }
  }

  /// Alias za kompatibilnost
  static String get apiBaseUrl => baseUrl;
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_51T6hBZCTVgVOvGUsDwWQGj588wzdirVATXce19ah3iMUzjeElXoetFCZTVAwbrMhgMuSmCoPFzhIP5xsfGEL4tDP00sa9PWkct',
  );
}

