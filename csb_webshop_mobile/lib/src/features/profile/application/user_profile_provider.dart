import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_api.dart';
import '../domain/user_profile.dart';

final Provider<ProfileApi> profileApiProvider = Provider<ProfileApi>((Ref ref) {
  return ProfileApi();
});

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  ProfileApi get _api => ref.read(profileApiProvider);

  @override
  Future<UserProfile?> build() async {
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

  Future<UserProfile?> ensureLoaded() async {
    final UserProfile? current = state.valueOrNull;
    if (current != null) {
      return current;
    }
    state = const AsyncLoading<UserProfile?>();
    state = await AsyncValue.guard(_load);
    return state.valueOrNull;
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String userName,
    String? phone,
    String? imageBase64,
  }) async {
    final UserProfile? current = state.value;
    // Optimistic update
    if (current != null) {
      state = AsyncData<UserProfile?>(
        current.copyWith(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        ),
      );
    }
    try {
      final UserProfile updated = await _api.updateMe(
        firstName: firstName,
        lastName: lastName,
        email: email,
        userName: userName,
        phone: phone,
        imageBase64: imageBase64,
      );
      state = AsyncData<UserProfile?>(updated);
    } catch (e, st) {
      state = AsyncError<UserProfile?>(e, st);
      rethrow;
    }
  }
}

final AsyncNotifierProvider<UserProfileNotifier, UserProfile?>
userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
