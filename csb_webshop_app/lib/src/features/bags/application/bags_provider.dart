import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bags_api.dart';
import '../domain/bag.dart';

final Provider<BagsApi> bagsApiProvider = Provider<BagsApi>((Ref ref) {
  return BagsApi();
});

class BagsListNotifier extends AsyncNotifier<List<Bag>> {
  late final BagsApi _api;

  int? _bagTypeId;
  String? _query;

  @override
  Future<List<Bag>> build() async {
    _api = ref.read(bagsApiProvider);
    _bagTypeId = null;
    _query = null;
    return _load();
  }

  String? get query => _query;

  Future<List<Bag>> _load() async {
    return _api.getBags(bagTypeId: _bagTypeId, query: _query);
  }

  Future<void> refresh({int? bagTypeId, String? query}) async {
    _bagTypeId = bagTypeId;
    _query = query;
    state = const AsyncLoading<List<Bag>>();
    state = await AsyncValue.guard(_load);
  }
}

final AsyncNotifierProvider<BagsListNotifier, List<Bag>> bagsListProvider =
    AsyncNotifierProvider<BagsListNotifier, List<Bag>>(BagsListNotifier.new);

