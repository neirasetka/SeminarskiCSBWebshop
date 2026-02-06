import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initializationSettings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final Map<String, dynamic> data = json.decode(payload) as Map<String, dynamic>;
          final int? orderId = data['orderId'] is int ? data['orderId'] as int : int.tryParse('${data['orderId']}');
          if (orderId != null) {
            rootNavigatorKey.currentContext?.go('/orders/$orderId');
          }
        } catch (_) {
          // Ignore malformed payloads
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'orders_channel',
      'Orders',
      description: 'Notifications about orders',
      importance: Importance.high,
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> showOrderNotification({required int orderId, required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'orders_channel',
      'Orders',
      channelDescription: 'Notifications about orders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    final String payload = json.encode(<String, dynamic>{'orderId': orderId});
    await _plugin.show(
      orderId,
      title,
      body,
      details,
      payload: payload,
    );
  }
}

