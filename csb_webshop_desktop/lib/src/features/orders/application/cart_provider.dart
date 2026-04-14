import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api_exception.dart';
import '../../profile/data/profile_api.dart';
import '../../profile/application/user_profile_provider.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Stripe Payment Sheet podržava samo Android, iOS i Web.
/// Na Windows/macOS/Linux desktopu nema native implementacije.
bool get _isStripeSupportedPlatform {
  if (kIsWeb) return true;
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

final Provider<OrdersApi> ordersApiProvider = Provider<OrdersApi>((Ref ref) => OrdersApi());

Future<T> _cartStep<T>(String stepLabelHr, Future<T> Function() action) async {
  try {
    return await action();
  } catch (e, st) {
    debugPrint('[Korpa — $stepLabelHr] $e\n$st');
    throw Exception('[Korpa — $stepLabelHr] ${ApiException.formatForDisplay(e)}');
  }
}

class CartNotifier extends AsyncNotifier<OrderModel?> {
  late final OrdersApi _api;
  late final ProfileApi _profileApi;

  @override
  Future<OrderModel?> build() async {
    _api = ref.read(ordersApiProvider);
    _profileApi = ref.read(profileApiProvider);
    return await _loadActiveCart();
  }

  Future<OrderModel?> _loadActiveCart() async {
    final int userId = (await _profileApi.getMe()).id;
    final map = await _api.getActiveCart(userId: userId);
    if (map == null) return null;
    return OrderModel.fromJson(map);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadActiveCart);
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
        '3) Kreiranje prazne narudžbe (GET /Users/me + POST /Orders/Create)',
        () async {
          final int userId = (await _profileApi.getMe()).id;
          if (userId < 1) {
            throw Exception('Neispravan korisnički profil. Prijavite se ponovno.');
          }
          final Map<String, dynamic> created = await _api.createOrder(
            userId: userId,
            orderNumber: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now(),
            price: 0,
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
    await _cartStep('5) Osvježavanje prikaza korpe nakon dodavanja', refresh);
  }

  /// Resets local cart state after successful payment (does not call backend).
  void resetCartAfterPayment() {
    state = const AsyncValue.data(null);
  }

  Future<void> clearCart() async {
    final OrderModel? order = state.value;
    if (order == null) {
      state = const AsyncValue.data(null);
      return;
    }
    final int userId = (await _profileApi.getMe()).id;
    await _api.cancelActiveCart(userId: userId);
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
        '3) Kreiranje prazne narudžbe (GET /Users/me + POST /Orders/Create)',
        () async {
          final int userId = (await _profileApi.getMe()).id;
          if (userId < 1) {
            throw Exception('Neispravan korisnički profil. Prijavite se ponovno.');
          }
          final Map<String, dynamic> created = await _api.createOrder(
            userId: userId,
            orderNumber: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now(),
            price: 0,
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
    await _cartStep('5) Osvježavanje prikaza korpe nakon dodavanja', refresh);
  }

  Future<Map<String, String>> startCheckout({String currency = 'eur', String? email}) async {
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

    final int amountInCents = (order.amount * 100).round();
    final Map<String, dynamic> resp = await _api.createPaymentIntent(
      orderId: order.id,
      amountInCents: amountInCents,
      currency: currency,
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
    await _api.updatePaymentStatus(orderId: order.id, status: 'Paid');
    await refresh();
    return <String, String>{
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

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Nije moguće otvoriti preglednik za plaćanje');
    }

    const Duration pollInterval = Duration(seconds: 3);
    const Duration timeout = Duration(minutes: 10);
    final DateTime deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollInterval);
      final Map<String, dynamic>? orderData = await _api.getOrder(orderId: order.id);
      if (orderData == null) continue;
      final String? status =
          (orderData['PaymentStatus'] ?? orderData['paymentStatus'])?.toString();
      if (status != null &&
          (status.toLowerCase() == 'paid' || status == '1')) {
        await refresh();
        return <String, String>{'sessionId': resp['SessionId']?.toString() ?? ''};
      }
    }

    throw Exception(
      'Plaćanje nije dovršeno u predviđenom vremenu. '
      'Ako ste platili, provjerite status narudžbe.',
    );
  }
}

final AsyncNotifierProvider<CartNotifier, OrderModel?> cartProvider =
    AsyncNotifierProvider<CartNotifier, OrderModel?>(CartNotifier.new);

