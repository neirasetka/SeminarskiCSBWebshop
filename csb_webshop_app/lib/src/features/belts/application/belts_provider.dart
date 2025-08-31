import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/belts_api.dart';
import '../domain/belt.dart';

final Provider<BeltsApi> beltsApiProvider = Provider<BeltsApi>((Ref ref) {
  return BeltsApi();
});

class BeltsListNotifier extends AsyncNotifier<List<Belt>> {
  late final BeltsApi _api;

  int? _beltTypeId;
  String? _query;

  @override
  Future<List<Belt>> build() async {
    _api = ref.read(beltsApiProvider);
    _beltTypeId = null;
    _query = null;
    return _load();
  }

  Future<List<Belt>> _load() async {
    return _api.getBelts(beltTypeId: _beltTypeId, query: _query);
  }

  Future<void> refresh({int? beltTypeId, String? query}) async {
    _beltTypeId = beltTypeId;
    _query = query;
    state = const AsyncLoading<List<Belt>>();
    state = await AsyncValue.guard(_load);
  }
}

final AsyncNotifierProvider<BeltsListNotifier, List<Belt>> beltsListProvider =
    AsyncNotifierProvider<BeltsListNotifier, List<Belt>>(BeltsListNotifier.new);

class BeltDetailNotifier extends AutoDisposeAsyncNotifier<Belt> {
  @override
  Future<Belt> build() async {
    throw UnimplementedError('Call fetch(id) first');
  }

  Future<void> fetch(int id) async {
    final BeltsApi api = ref.read(beltsApiProvider);
    state = const AsyncLoading<Belt>();
    state = await AsyncValue.guard(() => api.getBeltById(id));
  }
}

final AutoDisposeAsyncNotifierProvider<BeltDetailNotifier, Belt> beltDetailProvider =
    AutoDisposeAsyncNotifierProvider<BeltDetailNotifier, Belt>(BeltDetailNotifier.new);

