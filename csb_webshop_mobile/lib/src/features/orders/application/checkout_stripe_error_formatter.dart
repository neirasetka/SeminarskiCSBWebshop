import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Čitljiv jedan red za SnackBar / dijalog; puni `toString()` i dalje loguj u konzolu.
String formatCheckoutErrorForUi(Object error) {
  if (error is StripeException) {
    final LocalizedErrorMessage e = error.error;
    final String raw = '${e.localizedMessage ?? ''} ${e.message ?? ''}'.toLowerCase();
    if (e.stripeErrorCode == 'resource_missing' &&
        (raw.contains('payment_intent') || raw.contains('no such payment_intent'))) {
      return 'Plaćanje trenutno nije dostupno zbog Stripe konfiguracije. '
          'Pokušajte ponovo za par sekundi ili kontaktirajte podršku.';
    }
    final String? loc = e.localizedMessage?.trim();
    final String? msg = e.message?.trim();
    if (loc != null && loc.isNotEmpty) return loc;
    if (msg != null && msg.isNotEmpty) return msg;
    if (e.code == FailureCode.Canceled) {
      return 'Plaćanje je otkazano.';
    }
    return 'Stripe greška (${e.code}).';
  }
  if (error is StripeConfigException) {
    return error.message;
  }
  final String s = error.toString();
  if (s.startsWith('Exception: ')) {
    return s.substring('Exception: '.length);
  }
  return s;
}

/// Za `debugPrint` / logcat — više polja ako postoje.
String formatCheckoutErrorForLog(Object error) {
  if (error is StripeException) {
    final LocalizedErrorMessage e = error.error;
    return 'StripeException(code=${e.code}, localized=${e.localizedMessage}, '
        'message=${e.message}, stripeErrorCode=${e.stripeErrorCode}, '
        'declineCode=${e.declineCode}, type=${e.type})';
  }
  if (error is StripeConfigException) {
    return 'StripeConfigException: ${error.message}';
  }
  return error.toString();
}

void logCheckoutFailure(Object error, StackTrace stackTrace, {String? phase}) {
  final String phaseStr = phase != null ? '[$phase] ' : '';
  debugPrint('CHECKOUT_FAIL $phaseStr${formatCheckoutErrorForLog(error)}');
  debugPrint('$stackTrace');
}
