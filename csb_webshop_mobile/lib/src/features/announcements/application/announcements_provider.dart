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

  Future<void> addBagAnnouncement({
    required String bagName,
    required double price,
    required String color,
  }) async {
    final AnnouncementsApi api = ref.read(announcementsApiProvider);
    try {
      await api.createBagAnnouncement(
        bagName: bagName,
        price: price,
        color: color,
      );
      final List<Announcement> refreshed = await api.getAnnouncements();
      state = AsyncValue<List<Announcement>>.data(refreshed);
    } catch (Object error, StackTrace stackTrace) {
      state = AsyncValue<List<Announcement>>.error(error, stackTrace);
      rethrow;
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

