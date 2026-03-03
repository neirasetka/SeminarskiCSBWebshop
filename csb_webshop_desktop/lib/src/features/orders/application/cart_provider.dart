import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // Ensure cart exists
    OrderModel? order = state.value;
    if (order == null) {
      final int userId = (await _profileApi.getMe()).id;
      if (userId < 1) {
        throw Exception('Neispravan korisnički profil. Prijavite se ponovno.');
      }
      final created = await _api.createOrder(
        userId: userId,
        orderNumber: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        price: 0,
      );
      order = OrderModel.fromJson(created);
    }
    await _api.addItem(orderId: order.id, bagId: bagId, quantity: quantity, price: price);
    await refresh();
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
    OrderModel? order = state.value;
    if (order == null) {
      final int userId = (await _profileApi.getMe()).id;
      if (userId < 1) {
        throw Exception('Neispravan korisnički profil. Prijavite se ponovno.');
      }
      final created = await _api.createOrder(
        userId: userId,
        orderNumber: 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        price: 0,
      );
      order = OrderModel.fromJson(created);
    }
    await _api.addItem(orderId: order.id, beltId: beltId, quantity: quantity, price: price);
    await refresh();
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

