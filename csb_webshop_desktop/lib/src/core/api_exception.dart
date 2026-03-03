/// Exception from API calls with HTTP status and parsed error details.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.rawBody,
  });

  final int statusCode;
  final String message;
  final String? rawBody;

  @override
  String toString() => message;

  /// User-friendly display message with status context for debugging.
  String toDisplayString() {
    String statusHint = _statusHint(statusCode);
    if (message.isNotEmpty && message != statusHint) {
      return '$message${statusHint.isNotEmpty ? ' ($statusHint)' : ''}';
    }
    return statusHint.isNotEmpty ? statusHint : ' greška (HTTP $statusCode)';
  }

  static String _statusHint(int code) {
    switch (code) {
      case 400:
        return 'Neispravan zahtjev';
      case 401:
        return 'Niste prijavljeni – prijavite se ponovno';
      case 403:
        return 'Nemate dozvolu – provjerite ulogu korisnika (Buyer/Admin)';
      case 404:
        return 'Resurs nije pronađen';
      case 409:
        return 'Konflikt (npr. duplikat)';
      case 422:
        return 'Validacijska greška';
      case 500:
        return 'Greška na serveru';
      default:
        return 'HTTP $code';
    }
  }

  /// Try to extract ApiException from a generic Exception.
  static ApiException? from(Object e) {
    if (e is ApiException) return e;
    final String s = e.toString();
    final int? code = _tryParseStatus(s);
    if (code != null) {
      return ApiException(
        statusCode: code,
        message: s.replaceAll(RegExp(r'Exception:\s*'), '').trim(),
      );
    }
    return null;
  }

  static int? _tryParseStatus(String s) {
    final RegExpMatch? m = RegExp(r'\(?(\d{3})\)?').firstMatch(s);
    return m != null ? int.tryParse(m.group(1) ?? '') : null;
  }

  /// Format any error for display, preferring ApiException details.
  static String formatForDisplay(Object e) {
    final ApiException? api = from(e);
    if (api != null) return api.toDisplayString();
    final String s = e.toString();
    return s.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }
}
