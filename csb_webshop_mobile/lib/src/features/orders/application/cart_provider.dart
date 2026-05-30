import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../environment.dart';

import '../../profile/data/profile_api.dart';
import '../../profile/application/user_profile_provider.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

final Provider<OrdersApi> ordersApiProvider = Provider<OrdersApi>((Ref ref) => OrdersApi());

class CartNotifier extends AsyncNotifier<OrderModel?> {
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

  Future<void> addBagToCart({required int bagId, required double price, int quantity = 1}) async {
    if (bagId < 1) {
      throw Exception('Neispravan ID torbe. Osvježite katalog i pokušajte ponovno.');
    }
    // Ensure cart exists
    OrderModel? order = state.value;
    if (order == null) {
      order = await _loadActiveCart();
    }
    if (order == null) {
      final created = await _api.createOrder(
        orderNumber: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        price: 0,
      );
      order = OrderModel.fromJson(created);
    }
    await _api.addItem(orderId: order.id, bagId: bagId, quantity: quantity, price: price);
    await refresh();
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
      order = await _loadActiveCart();
    }
    if (order == null) {
      final created = await _api.createOrder(
        orderNumber: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        price: 0,
      );
      order = OrderModel.fromJson(created);
    }
    await _api.addItem(orderId: order.id, beltId: beltId, quantity: quantity, price: price);
    await refresh();
  }

  Future<Map<String, String>> startCheckout({String? email}) async {
    final String backendPk = await _api.getStripePublishableKey();
    final String appPk = EnvironmentConfig.stripePublishableKey.trim();
    final String effectivePk = backendPk.isNotEmpty ? backendPk : appPk;
    if (effectivePk.isEmpty || !effectivePk.startsWith('pk_')) {
      throw Exception('Stripe publishable key nije konfigurisan na API-ju.');
    }
    if (Stripe.publishableKey != effectivePk) {
      Stripe.publishableKey = effectivePk;
      await Stripe.instance.applySettings();
      if (kDebugMode) {
        debugPrint('[checkout] Stripe publishable key osvjezen iz API-ja.');
      }
    }

    final OrderModel? order = state.value ?? await _loadActiveCart();
    if (order == null) {
      throw Exception('Nema korpe za plaćanje');
    }
    // Use profile email if not provided
    String? receiptEmail = email;
    try {
      if (receiptEmail == null || receiptEmail.isEmpty) {
        receiptEmail = (await _profileApi.getMe()).email;
      }
    } catch (_) {}
    if (kDebugMode) {
      debugPrint('[checkout] orderId=${order.id}');
    }
    final Map<String, dynamic> resp = await _api.createPaymentIntent(
      orderId: order.id,
      receiptEmail: receiptEmail,
    );
    final String clientSecret = (resp['ClientSecret'] ?? resp['clientSecret'] ?? '').toString();
    if (clientSecret.isEmpty) {
      throw Exception('API nije vratio clientSecret za PaymentIntent.');
    }
    if (kDebugMode) {
      debugPrint('[checkout] PaymentIntent clientSecret primljen (duljina=${clientSecret.length})');
    }
    // Prepare and present PaymentSheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'CSB Webshop',
      ),
    );
    if (kDebugMode) {
      debugPrint('[checkout] initPaymentSheet OK, presentPaymentSheet...');
    }
    await Stripe.instance.presentPaymentSheet();
    if (kDebugMode) {
      debugPrint('[checkout] presentPaymentSheet OK, potvrđujem plaćanje na serveru...');
    }
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
      'clientSecret': clientSecret,
      'paymentIntentId': (resp['PaymentIntentId'] ?? resp['paymentIntentId'] ?? '').toString(),
    };
  }
}

final AsyncNotifierProvider<CartNotifier, OrderModel?> cartProvider =
    AsyncNotifierProvider<CartNotifier, OrderModel?>(CartNotifier.new);

