import 'dart:convert';

/// Parses ASP.NET error bodies: legacy `{error}`, `{message}`,
/// RFC 7807 Problem Details (`detail` / `title`), and `{errors}` validation maps.
class ApiErrorReader {
  ApiErrorReader._();

  static String readDetail(
    String body, {
    String fallback = '',
    String errorsSeparator = '; ',
  }) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return fallback.isNotEmpty ? fallback : '(prazan odgovor)';
    }

    try {
      final Object? decoded = json.decode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final String? fromMap = _readFromMap(decoded, errorsSeparator: errorsSeparator);
        if (fromMap != null && fromMap.isNotEmpty) {
          return fromMap;
        }
      } else if (decoded is String && decoded.isNotEmpty) {
        return decoded;
      }
    } catch (_) {
      /* nije JSON */
    }

    const int maxLen = 500;
    if (trimmed.length > maxLen) {
      return '${trimmed.substring(0, maxLen)}…';
    }
    return trimmed;
  }

  static String? _readFromMap(
    Map<String, dynamic> decoded, {
    required String errorsSeparator,
  }) {
    final Object? error = decoded['error'];
    if (error != null && error.toString().isNotEmpty) {
      return error.toString();
    }

    final Object? message = decoded['message'];
    if (message != null && message.toString().isNotEmpty) {
      return message.toString();
    }

    final Object? errors = decoded['errors'];
    if (errors is Map<String, dynamic>) {
      final List<String> parts = <String>[];
      for (final MapEntry<String, dynamic> e in errors.entries) {
        final Object? v = e.value;
        if (v is List) {
          for (final Object x in v) {
            parts.add('${e.key}: $x');
          }
        } else if (v != null) {
          parts.add('${e.key}: $v');
        }
      }
      if (parts.isNotEmpty) {
        return parts.join(errorsSeparator);
      }
    }

    final Object? detail = decoded['detail'];
    if (detail != null && detail.toString().isNotEmpty) {
      return detail.toString();
    }

    final Object? title = decoded['title'];
    if (title != null && title.toString().isNotEmpty) {
      return title.toString();
    }

    return null;
  }
}
