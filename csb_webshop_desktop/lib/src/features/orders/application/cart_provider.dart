import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';

import '../../../core/api_exception.dart';
import '../../profile/data/profile_api.dart';
import '../../profile/application/user_profile_provider.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Stripe Payment Sheet (flutter_stripe) na Androidu i iOS-u.
/// Na webu i desktopu koristi se hostirani Stripe Checkout (URL), ne Payment Sheet.
bool get _isStripeSupportedPlatform {
  if (kIsWeb) return false;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return false;
    default:
      return false;
  }
}

/// True kada se koristi Stripe Checkout u pregledniku i polling GET /Orders/{id} (desktop).
bool get cartUsesHostedStripeCheckout => !_isStripeSupportedPlatform;

final Provider<OrdersApi> ordersApiProvider = Provider<OrdersApi>((Ref ref) => OrdersApi());

Future<T> _cartStep<T>(String stepLabelHr, Future<T> Function() action) async {
  try {
    return await action();
  } catch (e, st) {
    debugPrint('[Korpa — $stepLabelHr] $e\n$st');
    throw Exception('[Korpa — $stepLabelHr] ${ApiException.formatForDisplay(e)}');
  }
}

Future<Webview> _openHostedCheckoutInApp(String url) async {
  if (kIsWeb) {
    throw Exception('In-app checkout nije podržan na web platformi.');
  }

  if (defaultTargetPlatform == TargetPlatform.windows) {
    final bool webViewAvailable = await WebviewWindow.isWebviewAvailable();
    if (!webViewAvailable) {
      throw Exception(
        'Nedostaje WebView2 runtime za in-app checkout. '
        'Instalirajte WebView2 runtime i pokušajte ponovno.',
      );
    }
  }

  final Webview webview = await WebviewWindow.create();
  webview
    ..setApplicationNameForUserAgent('CSB Webshop Desktop')
    ..launch(url);
  return webview;
}

class CartNotifier extends AsyncNotifier<OrderModel?> {
  // Getter: [build] se može ponoviti nakon invalidate (npr. nakon prijave).
  OrdersApi get _api => ref.read(ordersApiProvider);

  ProfileApi get _profileApi => ref.read(profileApiProvider);

  @override
  Future<OrderModel?> build() async {
    return await _loadActiveCart();
  }

  Future<OrderModel?> _loadActiveCart() async {
    final map = await _api.getActiveCart();
    if (map == null) return null;
    return OrderModel.fromJson(map);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadActiveCart);
  }

  /// Backend ponekad kasni par stotina ms nakon AddToCart.
  /// Retry izbjegava lažno "praznu korpu" odmah nakon dodavanja.
  Future<void> _refreshAfterAdd({required OrderModel fallbackOrder}) async {
    const int maxAttempts = 4;
    const Duration delayBetweenAttempts = Duration(milliseconds: 250);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final OrderModel? reloaded = await _loadActiveCart();
      if (reloaded != null && reloaded.items.isNotEmpty) {
        state = AsyncValue.data(reloaded);
        return;
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(delayBetweenAttempts);
      }
    }

    // Ako backend još nije vratio korpu, zadrži postojeću da UI ne "isprazni" korpu.
    state = AsyncValue.data(fallbackOrder);
  }

  Future<void> addBagToCart({required int bagId, required double price, int quantity = 1}) async {
    if (bagId < 1) {
      throw Exception('Neispravan ID torbe. Osvježite katalog i pokušajte ponovno.');
    }
    OrderModel? order = state.value;
    if (order == null) {
      order = await _cartStep(
        '2) Učitavanje aktivne korpe (GET /Orders/Active)',
        _loadActiveCart,
      );
    }
    if (order == null) {
      order = await _cartStep(
        '3) Kreiranje prazne narudžbe (POST /Orders/Create)',
        () async {
          final Map<String, dynamic> created = await _api.createOrder(
            orderNumber: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now(),
          );
          return OrderModel.fromJson(created);
        },
      );
    }
    final OrderModel cartOrder = order!;
    if (cartOrder.id < 1) {
      throw Exception(
        '[Korpa — provjera narudžbe] Server je vratio narudžbu bez valjanog OrderID (id=${cartOrder.id}). '
        'Odjavite se, ponovno se prijavite i pokušajte opet.',
      );
    }
    await _cartStep(
      '4) Dodavanje torbe (POST /OrderItems/AddToCart, bagId=$bagId, qty=$quantity)',
      () => _api.addItem(orderId: cartOrder.id, bagId: bagId, quantity: quantity, price: price),
    );
    await _cartStep(
      '5) Osvježavanje prikaza korpe nakon dodavanja',
      () => _refreshAfterAdd(fallbackOrder: cartOrder),
    );
  }

  /// Resets local cart state after successful payment (does not call backend).
  void resetCartAfterPayment() {
    state = const AsyncValue.data(null);
  }

  /// Briše aktivnu korpu na serveru dok je token još valjan (pri odjavi).
  Future<void> discardActiveCartOnLogout() async {
    try {
      await _api.cancelActiveCart();
    } catch (_) {
      // Mreža / istek tokena — ne blokiraj odjavu.
    }
    state = const AsyncValue<OrderModel?>.data(null);
  }

  Future<void> clearCart() async {
    final OrderModel? order = state.value;
    if (order == null) {
      state = const AsyncValue.data(null);
      return;
    }
    await _api.cancelActiveCart();
    await refresh();
  }

  Future<void> addBeltToCart({required int beltId, required double price, int quantity = 1}) async {
    if (beltId < 1) {
      throw Exception('Neispravan ID kaiša. Osvježite katalog i pokušajte ponovno.');
    }
    OrderModel? order = state.value;
    if (order == null) {
      order = await _cartStep(
        '2) Učitavanje aktivne korpe (GET /Orders/Active)',
        _loadActiveCart,
      );
    }
    if (order == null) {
      order = await _cartStep(
        '3) Kreiranje prazne narudžbe (POST /Orders/Create)',
        () async {
          final Map<String, dynamic> created = await _api.createOrder(
            orderNumber: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now(),
          );
          return OrderModel.fromJson(created);
        },
      );
    }
    final OrderModel cartOrder = order!;
    if (cartOrder.id < 1) {
      throw Exception(
        '[Korpa — provjera narudžbe] Server je vratio narudžbu bez valjanog OrderID (id=${cartOrder.id}). '
        'Odjavite se, ponovno se prijavite i pokušajte opet.',
      );
    }
    await _cartStep(
      '4) Dodavanje kaiša (POST /OrderItems/AddToCart, beltId=$beltId, qty=$quantity)',
      () => _api.addItem(orderId: cartOrder.id, beltId: beltId, quantity: quantity, price: price),
    );
    await _cartStep(
      '5) Osvježavanje prikaza korpe nakon dodavanja',
      () => _refreshAfterAdd(fallbackOrder: cartOrder),
    );
  }

  Future<Map<String, String>> startCheckout({String? email}) async {
    final OrderModel? order = state.value ?? await _loadActiveCart();
    if (order == null) {
      throw Exception('Nema korpe za plaćanje');
    }

    String? receiptEmail = email;
    try {
      if (receiptEmail == null || receiptEmail.isEmpty) {
        receiptEmail = (await _profileApi.getMe()).email;
      }
    } catch (_) {}

    if (!_isStripeSupportedPlatform) {
      return _startHostedCheckout(order: order, receiptEmail: receiptEmail);
    }

    final Map<String, dynamic> resp = await _api.createPaymentIntent(
      orderId: order.id,
      receiptEmail: receiptEmail,
    );
    final String clientSecret = (resp['ClientSecret'] ?? resp['clientSecret'] ?? '').toString();
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'CSB Webshop',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
    final String paymentIntentId =
        (resp['PaymentIntentId'] ?? resp['paymentIntentId'] ?? '').toString();
    if (paymentIntentId.isEmpty) {
      throw Exception('API nije vratio PaymentIntentId.');
    }
    final Map<String, dynamic> confirmResult = await _api.confirmPaymentIntent(
      paymentIntentId: paymentIntentId,
      orderId: order.id,
    );
    if (confirmResult['paid'] != true) {
      throw Exception('Plaćanje nije potvrđeno na serveru.');
    }
    await refresh();
    return <String, String>{
      'orderId': order.id.toString(),
      'clientSecret': clientSecret,
      'paymentIntentId': (resp['PaymentIntentId'] ?? resp['paymentIntentId'] ?? '').toString(),
    };
  }

  Future<Map<String, String>> _startHostedCheckout({
    required OrderModel order,
    String? receiptEmail,
  }) async {
    final Map<String, dynamic> resp = await _api.createCheckoutSession(
      orderId: order.id,
      receiptEmail: receiptEmail,
    );
    final String url = (resp['Url'] ?? resp['url'] ?? '').toString();
    if (url.isEmpty) {
      throw Exception('Nije moguće kreirati checkout sesiju');
    }

    final String successUrl =
        (resp['SuccessRedirectUrl'] ?? resp['successRedirectUrl'] ?? '').toString();
    final String cancelUrl =
        (resp['CancelRedirectUrl'] ?? resp['cancelRedirectUrl'] ?? '').toString();
    if (successUrl.isEmpty || cancelUrl.isEmpty) {
      throw Exception('Server nije vratio redirect URL-ove za checkout.');
    }

    final Webview checkoutWebview = await _openHostedCheckoutInApp(url);
    final Completer<String> checkoutOutcome = Completer<String>();

    checkoutWebview.addOnUrlRequestCallback((String requestedUrl) {
      final String lower = requestedUrl.toLowerCase();
      if (!checkoutOutcome.isCompleted &&
          lower.startsWith(successUrl)) {
        checkoutOutcome.complete('success');
      } else if (!checkoutOutcome.isCompleted &&
          lower.startsWith(cancelUrl)) {
        checkoutOutcome.complete('cancel');
      }
    });

    unawaited(checkoutWebview.onClose.then((_) {
      if (!checkoutOutcome.isCompleted) {
        checkoutOutcome.complete('closed');
      }
    }));

    final String outcome = await Future.any(<Future<String>>[
      checkoutOutcome.future,
      Future<String>.delayed(
        const Duration(minutes: 10),
        () => 'timeout',
      ),
    ]);

    if (outcome == 'cancel') {
      throw Exception('Plaćanje je otkazano.');
    }
    if (outcome == 'closed') {
      throw Exception('Checkout prozor je zatvoren prije potvrde plaćanja.');
    }
    if (outcome == 'timeout') {
      throw Exception('Plaćanje nije dovršeno u predviđenom vremenu.');
    }

    checkoutWebview.close();
    final String sessionId = resp['SessionId']?.toString() ?? '';

    if (sessionId.isEmpty) {
      throw Exception('Nedostaje sessionId za potvrdu plaćanja.');
    }

    final Map<String, dynamic> confirmResult = await _api.confirmCheckoutSession(
      sessionId: sessionId,
      orderId: order.id,
    );
    if (confirmResult['paid'] != true) {
      throw Exception('Plaćanje nije potvrđeno na serveru.');
    }

    await refresh();
    return <String, String>{
      'orderId': order.id.toString(),
      'sessionId': sessionId,
      'pending': '0',
    };
  }
}

final AsyncNotifierProvider<CartNotifier, OrderModel?> cartProvider =
    AsyncNotifierProvider<CartNotifier, OrderModel?>(CartNotifier.new);

