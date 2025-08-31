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
}

final AsyncNotifierProvider<BeltTypesNotifier, List<BeltType>> beltTypesProvider =
    AsyncNotifierProvider<BeltTypesNotifier, List<BeltType>>(BeltTypesNotifier.new);

