import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_session.dart';
import 'auth_controller.dart';
import '../../profile/data/profile_api.dart';

final Provider<ProfileApi> _profileApiProvider = Provider<ProfileApi>((Ref ref) => ProfileApi());

class AdminRoleNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final AuthSession? auth = await ref.watch(authControllerProvider.future);
    if (auth == null) {
      return false;
    }
    final ProfileApi api = ref.read(_profileApiProvider);
    return api.isAdmin();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<bool>();
    final AuthSession? auth = ref.read(authControllerProvider).valueOrNull;
    if (auth == null) {
      state = const AsyncData<bool>(false);
      return;
    }
    final ProfileApi api = ref.read(_profileApiProvider);
    state = await AsyncValue.guard(api.isAdmin);
  }
}

final AsyncNotifierProvider<AdminRoleNotifier, bool> adminRoleProvider =
    AsyncNotifierProvider<AdminRoleNotifier, bool>(AdminRoleNotifier.new);

