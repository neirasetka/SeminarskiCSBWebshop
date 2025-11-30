import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/announcement.dart';

class AnnouncementsApi {
  AnnouncementsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _newsPath = '/api/News';
  static const String _newCollectionPath = '/api/Announcements/new-collection';

  Future<List<Announcement>> getAnnouncements({int page = 1, int pageSize = 20, String? segment}) async {
    final Map<String, String> params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (segment != null && segment.isNotEmpty) 'segment': segment,
    };
    final String query = Uri(queryParameters: params).query;
    final String path = query.isEmpty ? _newsPath : '$_newsPath?$query';
    final http.Response response = await _apiClient.get(path);
    _ensureSuccess(response, 'load announcements');
    final List<dynamic> items = json.decode(response.body) as List<dynamic>;
    return items.map((dynamic e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Announcement> getAnnouncementById(int id) async {
    final http.Response response = await _apiClient.get('$_newsPath/$id');
    _ensureSuccess(response, 'load announcement $id');
    final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
    return Announcement.fromJson(map);
  }

  Future<void> createBagAnnouncement({
    required String bagName,
    required double price,
    required String color,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'subject': 'Nova torbica: $bagName',
      'body': 'Najavljujemo novu torbicu $bagName u $color boji po cijeni ${_formatPrice(price)} KM.',
      'segment': 'NewCollectionSubscribers',
      'productName': bagName,
      'price': price,
      'color': color,
    };

    final http.Response response = await _apiClient.post(_newCollectionPath, body: json.encode(body));
    _ensureSuccess(response, 'create announcement');
  }

  void _ensureSuccess(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to $action: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}

String _formatPrice(double price) {
  final bool hasDecimals = price.remainder(1) != 0;
  return hasDecimals ? price.toStringAsFixed(2) : price.toStringAsFixed(0);
}

