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
}

final AsyncNotifierProvider<BagTypesNotifier, List<BagType>> bagTypesProvider =
    AsyncNotifierProvider<BagTypesNotifier, List<BagType>>(BagTypesNotifier.new);

