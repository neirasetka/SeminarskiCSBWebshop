import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/belt_types_api.dart';
import '../domain/belt_type.dart';

final Provider<BeltTypesApi> beltTypesApiProvider = Provider<BeltTypesApi>((Ref ref) {
  return BeltTypesApi();
});

class BeltTypesNotifier extends AsyncNotifier<List<BeltType>> {
  late final BeltTypesApi _api;

  @override
  Future<List<BeltType>> build() async {
    _api = ref.read(beltTypesApiProvider);
    return _api.getBeltTypes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<BeltType>>();
    state = await AsyncValue.guard(() => _api.getBeltTypes());
  }

  Future<BeltType> create(String name) async {
    final BeltType created = await _api.createBeltType(name: name);
    await refresh();
    return created;
  }

  Future<BeltType> rename(int id, String name) async {
    final BeltType updated = await _api.updateBeltType(id: id, name: name);
    await refresh();
    return updated;
  }

  Future<void> remove(int id) async {
    await _api.deleteBeltType(id);
    await refresh();
  }
}

final AsyncNotifierProvider<BeltTypesNotifier, List<BeltType>> beltTypesProvider =
    AsyncNotifierProvider<BeltTypesNotifier, List<BeltType>>(BeltTypesNotifier.new);

