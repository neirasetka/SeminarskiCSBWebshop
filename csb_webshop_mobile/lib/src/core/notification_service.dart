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

    void onResponse(NotificationResponse response) {
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
    }

    // flutter_local_notifications has changed method signatures across versions.
    // This keeps compatibility by trying both named-only and positional variants.
    try {
      await Function.apply(
        (_plugin as dynamic).initialize,
        const <dynamic>[],
        <Symbol, dynamic>{
          #initializationSettings: initSettings,
          #onDidReceiveNotificationResponse: onResponse,
        },
      );
    } catch (_) {
      await (_plugin as dynamic).initialize(
        initSettings,
        onDidReceiveNotificationResponse: onResponse,
      );
    }

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
    try {
      await Function.apply(
        (_plugin as dynamic).show,
        const <dynamic>[],
        <Symbol, dynamic>{
          #id: orderId,
          #title: title,
          #body: body,
          #notificationDetails: details,
          #payload: payload,
        },
      );
    } catch (_) {
      try {
        await Function.apply(
          (_plugin as dynamic).show,
          const <dynamic>[],
          <Symbol, dynamic>{
            #id: orderId,
            #title: title,
            #body: body,
            #details: details,
            #payload: payload,
          },
        );
      } catch (_) {
        await (_plugin as dynamic).show(orderId, title, body, details, payload: payload);
      }
    }
  }
}

