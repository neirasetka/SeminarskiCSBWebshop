import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/paged_list_state.dart';
import '../data/belts_api.dart';
import '../domain/belt.dart';

final Provider<BeltsApi> beltsApiProvider = Provider<BeltsApi>((Ref ref) {
  return BeltsApi();
});

class BeltsListNotifier extends AsyncNotifier<PagedListState<Belt>> {
  static const int _pageSize = 20;

  BeltsApi get _api => ref.read(beltsApiProvider);

  int? _beltTypeId;
  String? _query;
  bool _loadingMore = false;

  @override
  Future<PagedListState<Belt>> build() async {
    _beltTypeId = null;
    _query = null;
    return _loadPage(1);
  }

  List<Belt> get items => state.valueOrNull?.items ?? const <Belt>[];

  Future<PagedListState<Belt>> _loadPage(int page) async {
    final result = await _api.getBelts(
      beltTypeId: _beltTypeId,
      query: _query,
      page: page,
      pageSize: _pageSize,
    );
    return PagedListState<Belt>(
      items: result.items,
      totalCount: result.totalCount,
      page: result.page,
      pageSize: result.pageSize,
    );
  }

  Future<void> loadFullCatalog({int? beltTypeId, String? query}) async {
    _beltTypeId = beltTypeId;
    _query = query;
    state = const AsyncLoading<PagedListState<Belt>>();
    state = await AsyncValue.guard(() async {
      final List<Belt> all = await _api.getAllBelts(beltTypeId: beltTypeId, query: query);
      return PagedListState<Belt>(
        items: all,
        totalCount: all.length,
        page: 1,
        pageSize: all.length,
      );
    });
  }

  Future<void> refresh({int? beltTypeId, String? query}) async {
    _beltTypeId = beltTypeId;
    _query = query;
    state = const AsyncLoading<PagedListState<Belt>>();
    state = await AsyncValue.guard(() => _loadPage(1));
  }

  Future<void> loadMore() async {
    final PagedListState<Belt>? current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;

    _loadingMore = true;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final result = await _api.getBelts(
        beltTypeId: _beltTypeId,
        query: _query,
        page: current.page + 1,
        pageSize: _pageSize,
      );
      state = AsyncData(
        PagedListState<Belt>(
          items: <Belt>[...current.items, ...result.items],
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

  Future<Belt> create({
    required String name,
    required String code,
    required double price,
    String description = '',
    int? beltTypeId,
    String? imageBase64,
    int? userId,
  }) async {
    final Belt created = await _api.createBelt(
      name: name,
      code: code,
      price: price,
      description: description,
      beltTypeId: beltTypeId,
      imageBase64: imageBase64,
      userId: userId,
    );
    await refresh(beltTypeId: _beltTypeId, query: _query);
    return created;
  }

  Future<Belt> edit({
    required int id,
    required String name,
    required String code,
    required double price,
    String description = '',
    int? beltTypeId,
    String? imageBase64,
    int? userId,
  }) async {
    final Belt updated = await _api.updateBelt(
      id: id,
      name: name,
      code: code,
      price: price,
      description: description,
      beltTypeId: beltTypeId,
      imageBase64: imageBase64,
      userId: userId,
    );
    await refresh(beltTypeId: _beltTypeId, query: _query);
    return updated;
  }

  Future<void> remove(int id) async {
    await _api.deleteBelt(id);
    await refresh(beltTypeId: _beltTypeId, query: _query);
  }
}

final AsyncNotifierProvider<BeltsListNotifier, PagedListState<Belt>> beltsListProvider =
    AsyncNotifierProvider<BeltsListNotifier, PagedListState<Belt>>(BeltsListNotifier.new);

class BeltDetailNotifier extends AutoDisposeFamilyAsyncNotifier<Belt, int> {
  @override
  Future<Belt> build(int id) async {
    final BeltsApi api = ref.read(beltsApiProvider);
    return api.getBeltById(id);
  }
}

final beltDetailProvider = AsyncNotifierProvider.autoDispose
    .family<BeltDetailNotifier, Belt, int>(BeltDetailNotifier.new);
