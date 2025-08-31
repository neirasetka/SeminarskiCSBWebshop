import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple environment/flavor loader based on --dart-define=APP_ENV
/// Supported values: dev, staging, prod
class Env {
  Env._();

  static const String _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static String get flavor => _appEnv;

  static Future<void> load() async {
    final String fileName;
    switch (_appEnv) {
      case 'prod':
        fileName = 'assets/env/.env.prod';
        break;
      case 'staging':
        fileName = 'assets/env/.env.staging';
        break;
      case 'dev':
      default:
        fileName = 'assets/env/.env.dev';
        break;
    }
    if (kDebugMode) {
      // Print which env is being loaded to help during development
      // ignore: avoid_print
      print('Loading env: $_appEnv from $fileName');
    }
    await dotenv.load(fileName: fileName);
  }

  static String get apiBaseUrl => dotenv.get('API_BASE_URL');
  static String get sentryDsn => dotenv.maybeGet('SENTRY_DSN') ?? '';
}

