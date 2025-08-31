import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_api.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

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

  Future<void> addBeltToCart({required int beltId, required double price, int quantity = 1}) async {
    OrderModel? order = state.value;
    if (order == null) {
      final int userId = (await _profileApi.getMe()).id;
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
    final int amountInCents = (order.amount * 100).round();
    final Map<String, dynamic> resp = await _api.createPaymentIntent(
      orderId: order.id,
      amountInCents: amountInCents,
      currency: currency,
      receiptEmail: email,
    );
    final String clientSecret = (resp['ClientSecret'] ?? resp['clientSecret'] ?? '').toString();
    // Prepare and present PaymentSheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'CSB Webshop',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
    return <String, String>{
      'clientSecret': clientSecret,
      'paymentIntentId': (resp['PaymentIntentId'] ?? resp['paymentIntentId'] ?? '').toString(),
    };
  }
}

final AsyncNotifierProvider<CartNotifier, OrderModel?> cartProvider =
    AsyncNotifierProvider<CartNotifier, OrderModel?>(CartNotifier.new);

