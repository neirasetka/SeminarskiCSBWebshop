import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/notifications_provider.dart';

class NotificationBadgeButton extends ConsumerWidget {
  const NotificationBadgeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int unreadCount = ref.watch(unreadNotificationsProvider);

    return IconButton(
      tooltip: 'Obavijesti',
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
