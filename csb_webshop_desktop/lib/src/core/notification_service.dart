import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_windows/flutter_local_notifications_windows.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      const WindowsInitializationSettings windowsInit = WindowsInitializationSettings(
        appName: 'CSB Webshop',
        appUserModelId: 'CocoSunBags.CSBWebshop.Desktop.1',
        guid: 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
      );
      initSettings = const InitializationSettings(android: androidInit, windows: windowsInit);
    } else {
      initSettings = const InitializationSettings(android: androidInit);
    }

    await _plugin.initialize(
      initSettings,
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
    await _plugin.show(orderId, title, body, details, payload: payload);
  }
}

