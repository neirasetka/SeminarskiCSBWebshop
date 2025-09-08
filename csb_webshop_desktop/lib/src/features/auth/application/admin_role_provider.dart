import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_api.dart';

final Provider<ProfileApi> _profileApiProvider = Provider<ProfileApi>((Ref ref) => ProfileApi());

class AdminRoleNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final ProfileApi api = ref.read(_profileApiProvider);
    return api.isAdmin();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<bool>();
    final ProfileApi api = ref.read(_profileApiProvider);
    state = await AsyncValue.guard(api.isAdmin);
  }
}

final AsyncNotifierProvider<AdminRoleNotifier, bool> adminRoleProvider =
    AsyncNotifierProvider<AdminRoleNotifier, bool>(AdminRoleNotifier.new);

