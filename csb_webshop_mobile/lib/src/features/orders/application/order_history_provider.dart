import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/paged_list_state.dart';
import '../../auth/application/auth_controller.dart';
import '../data/orders_api.dart';
import '../domain/order_models.dart';

final Provider<OrdersApi> _ordersApiProvider = Provider<OrdersApi>((Ref ref) => OrdersApi());

class OrderHistoryNotifier extends AsyncNotifier<PagedListState<OrderModel>> {
  static const int _pageSize = 20;

  OrdersApi get _api => ref.read(_ordersApiProvider);
  bool _loadingMore = false;

  PagedListState<OrderModel> get _emptyState => PagedListState<OrderModel>(
        items: const <OrderModel>[],
        totalCount: 0,
        page: 1,
        pageSize: _pageSize,
      );

  @override
  Future<PagedListState<OrderModel>> build() async {
    final auth = await ref.watch(authControllerProvider.future);
    if (auth == null) {
      return _emptyState;
    }
    return _loadPage(1);
  }

  Future<PagedListState<OrderModel>> _loadPage(int page) async {
    final result = await _api.getMyOrders(page: page, pageSize: _pageSize);
    return PagedListState<OrderModel>(
      items: result.items.map(OrderModel.fromJson).toList(),
      totalCount: result.totalCount,
      page: result.page,
      pageSize: result.pageSize,
    );
  }

  Future<void> refresh() async {
    final auth = ref.read(authControllerProvider).valueOrNull;
    if (auth == null) {
      state = AsyncData(_emptyState);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  Future<void> loadMore() async {
    final PagedListState<OrderModel>? current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;

    _loadingMore = true;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await _api.getMyOrders(page: current.page + 1, pageSize: _pageSize);
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

final AsyncNotifierProvider<OrderHistoryNotifier, PagedListState<OrderModel>> orderHistoryProvider =
    AsyncNotifierProvider<OrderHistoryNotifier, PagedListState<OrderModel>>(OrderHistoryNotifier.new);
