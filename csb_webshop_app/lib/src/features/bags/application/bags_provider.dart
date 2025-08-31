import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bags_api.dart';
import '../domain/bag.dart';

final Provider<BagsApi> bagsApiProvider = Provider<BagsApi>((Ref ref) {
  return BagsApi();
});

class BagsListNotifier extends AsyncNotifier<List<Bag>> {
  late final BagsApi _api;

  int _page = 1;
  bool _hasMore = true;
  String? _query;

  @override
  Future<List<Bag>> build() async {
    _api = ref.read(bagsApiProvider);
    _page = 1;
    _hasMore = true;
    _query = null;
    return _load(reset: true);
  }

  bool get hasMore => _hasMore;
  String? get query => _query;

  Future<List<Bag>> _load({required bool reset}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
    }
    final List<Bag> current = reset ? <Bag>[] : (state.value ?? <Bag>[]);
    final List<Bag> next = await _api.getBags(page: _page, pageSize: 20, query: _query);
    _hasMore = next.length == 20;
    _page += 1;
    return <Bag>[...current, ...next];
  }

  Future<void> refresh({String? query}) async {
    _query = query;
    state = const AsyncLoading<List<Bag>>();
    state = await AsyncValue.guard(() => _load(reset: true));
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final List<Bag> current = state.value ?? <Bag>[];
    state = AsyncData<List<Bag>>(current);
    final List<Bag> more = await _api.getBags(page: _page, pageSize: 20, query: _query);
    _hasMore = more.length == 20;
    _page += 1;
    state = AsyncData<List<Bag>>(<Bag>[...current, ...more]);
  }
}

final AsyncNotifierProvider<BagsListNotifier, List<Bag>> bagsListProvider =
    AsyncNotifierProvider<BagsListNotifier, List<Bag>>(BagsListNotifier.new);

