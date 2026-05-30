import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/notification_model.dart';
import '../data/notifications_api.dart';

final Provider<NotificationsApi> notificationsApiProvider =
    Provider<NotificationsApi>((Ref ref) => NotificationsApi());

class UnreadNotificationsNotifier extends Notifier<int> {
  Timer? _pollTimer;
  NotificationsApi get _api => ref.read(notificationsApiProvider);

  @override
  int build() {
    ref.onDispose(() => _pollTimer?.cancel());
    ref.listen(authControllerProvider, (_, __) {
      unawaited(refresh());
    });
    _startPolling();
    unawaited(refresh());
    return 0;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(refresh());
    });
  }

  Future<void> refresh() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) {
      state = 0;
      return;
    }
    try {
      state = await _api.getUnreadCount();
    } catch (_) {
      // Keep last known count on transient errors.
    }
  }
}

final NotifierProvider<UnreadNotificationsNotifier, int> unreadNotificationsProvider =
    NotifierProvider<UnreadNotificationsNotifier, int>(UnreadNotificationsNotifier.new);

class NotificationsListNotifier extends AsyncNotifier<List<NotificationModel>> {
  NotificationsApi get _api => ref.read(notificationsApiProvider);

  @override
  Future<List<NotificationModel>> build() async {
    return _load();
  }

  Future<List<NotificationModel>> _load() async {
    final session = ref.read(authControllerProvider).valueOrNull;
    if (session == null) return <NotificationModel>[];
    return _api.getNotifications(1, 50);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
    await ref.read(unreadNotificationsProvider.notifier).refresh();
  }

  Future<void> markAsRead(int id) async {
    await _api.markAsRead(id);
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await _api.markAllAsRead();
    await refresh();
  }
}

final AsyncNotifierProvider<NotificationsListNotifier, List<NotificationModel>>
    notificationsListProvider =
    AsyncNotifierProvider<NotificationsListNotifier, List<NotificationModel>>(
        NotificationsListNotifier.new);
