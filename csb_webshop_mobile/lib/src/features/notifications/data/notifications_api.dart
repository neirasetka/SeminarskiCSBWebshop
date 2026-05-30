import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/paged_result.dart';
import 'notification_model.dart';

class NotificationsApi {
  NotificationsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _basePath = '/api/Notifications';

  Future<List<NotificationModel>> getNotifications(int page, int pageSize) async {
    final http.Response response =
        await _apiClient.get('$_basePath?page=$page&pageSize=$pageSize');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return PagedResult.fromJson(map, NotificationModel.fromJson).items;
    }
    throw Exception('Failed to load notifications: ${response.statusCode}');
  }

  Future<int> getUnreadCount() async {
    final http.Response response = await _apiClient.get('$_basePath/unread-count');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return int.tryParse(response.body) ?? 0;
    }
    throw Exception('Failed to get unread count: ${response.statusCode}');
  }

  Future<void> markAsRead(int id) async {
    final http.Response response = await _apiClient.patch('$_basePath/$id/read');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to mark notification as read: ${response.statusCode}');
  }

  Future<void> markAllAsRead() async {
    final http.Response response = await _apiClient.patch('$_basePath/read-all');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
  }
}
