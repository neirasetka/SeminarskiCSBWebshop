import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bag_types_api.dart';
import '../domain/bag_type.dart';

final Provider<BagTypesApi> bagTypesApiProvider = Provider<BagTypesApi>((Ref ref) {
  return BagTypesApi();
});

class BagTypesNotifier extends AsyncNotifier<List<BagType>> {
  late final BagTypesApi _api;

  @override
  Future<List<BagType>> build() async {
    _api = ref.read(bagTypesApiProvider);
    return _api.getBagTypes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<BagType>>();
    state = await AsyncValue.guard(() => _api.getBagTypes());
  }

  Future<BagType> create(String name) async {
    final BagType created = await _api.createBagType(name: name);
    await refresh();
    return created;
  }

  Future<BagType> rename(int id, String name) async {
    final BagType updated = await _api.updateBagType(id: id, name: name);
    await refresh();
    return updated;
  }

  Future<void> remove(int id) async {
    await _api.deleteBagType(id);
    await refresh();
  }
}

final AsyncNotifierProvider<BagTypesNotifier, List<BagType>> bagTypesProvider =
    AsyncNotifierProvider<BagTypesNotifier, List<BagType>>(BagTypesNotifier.new);

