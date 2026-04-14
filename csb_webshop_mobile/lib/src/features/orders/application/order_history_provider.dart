import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_api.dart';
import '../../profile/application/user_profile_provider.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';

final Provider<OrdersApi> _ordersApiProvider = Provider<OrdersApi>((Ref ref) => OrdersApi());

class OrderHistoryNotifier extends AsyncNotifier<List<OrderModel>> {
  OrdersApi get _api => ref.read(_ordersApiProvider);
  ProfileApi get _profileApi => ref.read(profileApiProvider);

  @override
  Future<List<OrderModel>> build() async {
    return _load();
  }

  Future<List<OrderModel>> _load() async {
    final int userId = (await _profileApi.getMe()).id;
    final List<Map<String, dynamic>> raw = await _api.getOrdersByUser(userId: userId);
    return raw.map(OrderModel.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }
}

final AsyncNotifierProvider<OrderHistoryNotifier, List<OrderModel>> orderHistoryProvider =
    AsyncNotifierProvider<OrderHistoryNotifier, List<OrderModel>>(OrderHistoryNotifier.new);

