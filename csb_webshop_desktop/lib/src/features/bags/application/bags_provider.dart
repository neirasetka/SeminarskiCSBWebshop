import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/paged_list_state.dart';
import '../data/bags_api.dart';
import '../domain/bag.dart';

final Provider<BagsApi> bagsApiProvider = Provider<BagsApi>((Ref ref) {
  return BagsApi();
});

class BagsListNotifier extends AsyncNotifier<PagedListState<Bag>> {
  static const int _pageSize = 20;

  BagsApi get _api => ref.read(bagsApiProvider);

  int? _bagTypeId;
  String? _query;
  bool _loadingMore = false;

  @override
  Future<PagedListState<Bag>> build() async {
    _bagTypeId = null;
    _query = null;
    return _loadPage(1);
  }

  String? get query => _query;
  List<Bag> get items => state.valueOrNull?.items ?? const <Bag>[];

  Future<PagedListState<Bag>> _loadPage(int page) async {
    final result = await _api.getBags(
      bagTypeId: _bagTypeId,
      query: _query,
      page: page,
      pageSize: _pageSize,
    );
    return PagedListState<Bag>(
      items: result.items,
      totalCount: result.totalCount,
      page: result.page,
      pageSize: result.pageSize,
    );
  }

  Future<void> loadFullCatalog({int? bagTypeId, String? query}) async {
    _bagTypeId = bagTypeId;
    _query = query;
    state = const AsyncLoading<PagedListState<Bag>>();
    state = await AsyncValue.guard(() async {
      final List<Bag> all = await _api.getAllBags(bagTypeId: bagTypeId, query: query);
      return PagedListState<Bag>(
        items: all,
        totalCount: all.length,
        page: 1,
        pageSize: all.length,
      );
    });
  }

  Future<void> refresh({int? bagTypeId, String? query}) async {
    _bagTypeId = bagTypeId;
    _query = query;
    state = const AsyncLoading<PagedListState<Bag>>();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  Future<void> loadMore() async {
    final PagedListState<Bag>? current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;

    _loadingMore = true;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await _api.getBags(
        bagTypeId: _bagTypeId,
        query: _query,
        page: current.page + 1,
        pageSize: _pageSize,
      );
      state = AsyncData(
        PagedListState<Bag>(
          items: <Bag>[...current.items, ...result.items],
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

  Future<Bag> create({
    required String name,
    required String code,
    required double price,
    String description = '',
    int? bagTypeId,
    String? imageBase64,
    int? userId,
  }) async {
    final Bag created = await _api.createBag(
      name: name,
      code: code,
      price: price,
      description: description,
      bagTypeId: bagTypeId,
      imageBase64: imageBase64,
      userId: userId,
    );
    await refresh(bagTypeId: _bagTypeId, query: _query);
    return created;
  }

  Future<Bag> edit({
    required int id,
    required String name,
    required String code,
    required double price,
    String description = '',
    int? bagTypeId,
    String? imageBase64,
    int? userId,
  }) async {
    final Bag updated = await _api.updateBag(
      id: id,
      name: name,
      code: code,
      price: price,
      description: description,
      bagTypeId: bagTypeId,
      imageBase64: imageBase64,
      userId: userId,
    );
    await refresh(bagTypeId: _bagTypeId, query: _query);
    return updated;
  }

  Future<void> remove(int id) async {
    await _api.deleteBag(id);
    await refresh(bagTypeId: _bagTypeId, query: _query);
  }
}

final AsyncNotifierProvider<BagsListNotifier, PagedListState<Bag>> bagsListProvider =
    AsyncNotifierProvider<BagsListNotifier, PagedListState<Bag>>(BagsListNotifier.new);

class BagDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Bag, int> {
  @override
  Future<Bag> build(int id) async {
    final BagsApi api = ref.read(bagsApiProvider);
    return api.getBagById(id);
  }
}

final bagDetailProvider = AsyncNotifierProvider.autoDispose
    .family<BagDetailNotifier, Bag, int>(BagDetailNotifier.new);
