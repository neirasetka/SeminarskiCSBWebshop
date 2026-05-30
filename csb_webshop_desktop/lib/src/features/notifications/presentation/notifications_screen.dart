import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/notifications_provider.dart';
import '../data/notification_model.dart';
import '../../../utils/date_formatter.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsListProvider.notifier).refresh();
    });
  }

  Future<void> _openNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      await ref.read(notificationsListProvider.notifier).markAsRead(notification.notificationID);
    }
    if (!mounted) return;

    final int? orderId = notification.relatedEntityID;
    if (orderId != null &&
        (notification.type.startsWith('Order') || notification.type == 'OrderShipping')) {
      context.push('/orders/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<NotificationModel>> notificationsAsync =
        ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obavijesti'),
        actions: <Widget>[
          TextButton(
            onPressed: () => ref.read(notificationsListProvider.notifier).markAllAsRead(),
            child: const Text('Označi sve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(notificationsListProvider.notifier).refresh(),
                  child: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          ),
        ),
        data: (List<NotificationModel> notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('Nema obavijesti'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsListProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (BuildContext context, int index) {
                final NotificationModel n = notifications[index];
                return ListTile(
                  onTap: () => _openNotification(n),
                  leading: Icon(
                    n.isRead ? Icons.notifications_none : Icons.notifications_active,
                    color: n.isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(n.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.formatDateTime(n.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: n.isRead
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () => ref
                              .read(notificationsListProvider.notifier)
                              .markAsRead(n.notificationID),
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
