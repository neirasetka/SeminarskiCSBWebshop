import 'package:flutter/material.dart';
import '../data/notification_model.dart';
import '../data/notifications_api.dart';
import '../../../utils/date_formatter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsApi _api = NotificationsApi();
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getNotifications(1, 50);
      setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    await _api.markAsRead(id);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _api.markAllAsRead();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obavijesti'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Označi sve kao pročitano',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Nema obavijesti'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return ListTile(
                        leading: Icon(
                          n.isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: n.isRead ? Colors.grey : Colors.blue,
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight:
                                n.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                onPressed: () => _markAsRead(n.notificationID),
                              ),
                      );
                    },
                  ),
                ),
    );
  }
}
