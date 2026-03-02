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

final AsyncNotifierProvider<BeltsListNotifier, List<Belt>> beltsListProvider =
    AsyncNotifierProvider<BeltsListNotifier, List<Belt>>(BeltsListNotifier.new);

/// Provider za detalje jednog kaiša po ID-u.
/// Korištenjem family providera, fetch se poziva automatski pri prvom watch-u,
/// što sprječava grešku "Call fetch(id) first".
final beltDetailProvider =
    FutureProvider.autoDispose.family<Belt, int>((Ref ref, int id) async {
  final BeltsApi api = ref.read(beltsApiProvider);
  return api.getBeltById(id);
});

