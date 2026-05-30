import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/paged_list_state.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';
import 'cart_provider.dart';

class AdminOrdersListNotifier extends AsyncNotifier<PagedListState<OrderModel>> {
  static const int _pageSize = 20;

  OrdersApi get _api => ref.read(ordersApiProvider);
  bool _loadingMore = false;
  String? _orderNumberPrefix;

  @override
  Future<PagedListState<OrderModel>> build() async {
    _orderNumberPrefix = null;
    return _loadPage(1);
  }

  Future<PagedListState<OrderModel>> _loadPage(int page) async {
    final result = await _api.listOrdersPage(
      orderNumberPrefix: _orderNumberPrefix,
      page: page,
      pageSize: _pageSize,
    );
    return PagedListState<OrderModel>(
      items: result.items.map(OrderModel.fromJson).toList(),
      totalCount: result.totalCount,
      page: result.page,
      pageSize: result.pageSize,
    );
  }

  Future<void> refresh({String? orderNumberPrefix}) async {
    _orderNumberPrefix = orderNumberPrefix?.trim().isEmpty == true ? null : orderNumberPrefix?.trim();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  Future<void> loadMore() async {
    final PagedListState<OrderModel>? current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;

    _loadingMore = true;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await _api.listOrdersPage(
        orderNumberPrefix: _orderNumberPrefix,
        page: current.page + 1,
        pageSize: _pageSize,
      );
      state = AsyncData(
        PagedListState<OrderModel>(
          items: <OrderModel>[...current.items, ...result.items.map(OrderModel.fromJson)],
          totalCount: result.totalCount,
          page: result.page,
          pageSize: result.pageSize,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      _loadingMore = false;
    }
  }
}

final AsyncNotifierProvider<AdminOrdersListNotifier, PagedListState<OrderModel>> adminOrdersListProvider =
    AsyncNotifierProvider<AdminOrdersListNotifier, PagedListState<OrderModel>>(AdminOrdersListNotifier.new);
