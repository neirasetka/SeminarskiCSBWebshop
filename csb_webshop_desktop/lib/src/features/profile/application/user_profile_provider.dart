import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_api.dart';
import '../domain/user_profile.dart';

final Provider<ProfileApi> profileApiProvider = Provider<ProfileApi>((Ref ref) {
  return ProfileApi();
});

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  late final ProfileApi _api;

  @override
  Future<UserProfile?> build() async {
    _api = ref.read(profileApiProvider);
    return _load();
  }

  Future<UserProfile?> _load() async {
    try {
      final UserProfile profile = await _api.getMe();
      return profile;
    } catch (e) {
      // For unauthorized or errors, return null and let UI handle
      return null;
    }
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading<UserProfile?>();
    state = await AsyncValue.guard(_load);
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String userName,
    String? imageBase64,
  }) async {
    final UserProfile? current = state.value;
    try {
      final UserProfile updated = await _api.updateMe(
        firstName: firstName,
        lastName: lastName,
        email: email,
        userName: userName,
        imageBase64: imageBase64,
      );
      state = AsyncData<UserProfile?>(updated);
    } catch (e, st) {
      state = AsyncError<UserProfile?>(e, st);
      rethrow;
    }
  }
}

final AsyncNotifierProvider<UserProfileNotifier, UserProfile?> userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(UserProfileNotifier.new);

