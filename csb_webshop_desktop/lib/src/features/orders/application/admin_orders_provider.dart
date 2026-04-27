import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/orders_api.dart';
import '../domain/order_models.dart';
import 'cart_provider.dart';

final AutoDisposeFutureProvider<List<OrderModel>> adminOrdersListProvider =
    AutoDisposeFutureProvider<List<OrderModel>>((Ref ref) async {
  final OrdersApi api = ref.watch(ordersApiProvider);
  final List<Map<String, dynamic>> raw = await api.listAllOrders();
  return raw.map(OrderModel.fromJson).toList();
});
