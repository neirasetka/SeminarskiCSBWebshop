import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/announcements_api.dart';
import '../domain/announcement.dart';

final Provider<AnnouncementsApi> announcementsApiProvider =
    Provider<AnnouncementsApi>((Ref ref) => AnnouncementsApi());

class AnnouncementsListNotifier extends AsyncNotifier<List<Announcement>> {
  @override
  Future<List<Announcement>> build() async {
    final AnnouncementsApi api = ref.read(announcementsApiProvider);
    return api.getAnnouncements();
    
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Announcement>>();
    final AnnouncementsApi api = ref.read(announcementsApiProvider);
    state = await AsyncValue.guard(api.getAnnouncements);
  }

  /// Creates a new bag announcement and refreshes the list.
  /// Returns the created announcement on success, null on failure.
  Future<Announcement?> createBagAnnouncement({
    required String bagName,
    required double bagPrice,
    required String bagColor,
  }) async {
    final AnnouncementsApi api = ref.read(announcementsApiProvider);
    try {
      final Announcement created = await api.createBagAnnouncement(
        bagName: bagName,
        bagPrice: bagPrice,
        bagColor: bagColor,
      );
      // Refresh the list to include the new announcement
      await refresh();
      return created;
    } catch (e) {
      return null;
    }
  }

  /// Updates an existing announcement and refreshes the list.
  /// Returns the updated announcement on success, null on failure.
  Future<Announcement?> updateAnnouncement(
    int id, {
    required String title,
    required String body,
    required AnnouncementType type,
  }) async {
    final AnnouncementsApi api = ref.read(announcementsApiProvider);
    try {
      final Announcement updated = await api.updateAnnouncement(
        id,
        title: title,
        body: body,
        type: type,
      );
      await refresh();
      return updated;
    } catch (e) {
      return null;
    }
  }
}

final AsyncNotifierProvider<AnnouncementsListNotifier, List<Announcement>> announcementsListProvider =
    AsyncNotifierProvider<AnnouncementsListNotifier, List<Announcement>>(AnnouncementsListNotifier.new);

class AnnouncementDetailNotifier extends AutoDisposeAsyncNotifier<Announcement> {
  @override
  Future<Announcement> build() async {
    throw UnimplementedError('Call fetch(id) first');
  }

  Future<void> fetch(int id) async {
    final AnnouncementsApi api = ref.read(announcementsApiProvider);
    state = const AsyncLoading<Announcement>();
    state = await AsyncValue.guard(() => api.getAnnouncementById(id));
  }
}

final AutoDisposeAsyncNotifierProvider<AnnouncementDetailNotifier, Announcement> announcementDetailProvider =
    AutoDisposeAsyncNotifierProvider<AnnouncementDetailNotifier, Announcement>(AnnouncementDetailNotifier.new);

