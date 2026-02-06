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

final AsyncNotifierProvider<BagsListNotifier, List<Bag>> bagsListProvider =
    AsyncNotifierProvider<BagsListNotifier, List<Bag>>(BagsListNotifier.new);

class BagDetailNotifier extends AutoDisposeAsyncNotifier<Bag> {
  @override
  Future<Bag> build() async {
    throw UnimplementedError('Call fetch(id) first');
  }

  Future<void> fetch(int id) async {
    final BagsApi api = ref.read(bagsApiProvider);
    state = const AsyncLoading<Bag>();
    state = await AsyncValue.guard(() => api.getBagById(id));
  }
}

final bagDetailProvider =
    AsyncNotifierProvider.autoDispose<BagDetailNotifier, Bag>(BagDetailNotifier.new);

