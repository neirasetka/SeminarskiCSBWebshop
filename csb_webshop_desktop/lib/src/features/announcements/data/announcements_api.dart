import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/paged_result.dart';
import '../domain/announcement.dart';

class AnnouncementsApi {
  AnnouncementsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _newsPath = '/api/News';

  Future<List<Announcement>> getAnnouncements({int page = 1, int pageSize = 20, String? segment}) async {
    final Map<String, String> params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (segment != null && segment.isNotEmpty) 'segment': segment,
    };
    final String query = Uri(queryParameters: params).query;
    final String path = query.isEmpty ? _newsPath : '$_newsPath?$query';
    final http.Response response = await _apiClient.get(path);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GET $_newsPath nije uspio: HTTP ${response.statusCode}');
    }
    final dynamic decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) {
      return PagedResult.fromJson(decoded, Announcement.fromNewsJson).items;
    }
    if (decoded is List<dynamic>) {
      return decoded
          .map((dynamic e) => Announcement.fromNewsJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Neočekivani odgovor s $_newsPath');
  }

  Future<Announcement> getAnnouncementById(int id) async {
    final http.Response response = await _apiClient.get('$_newsPath/$id');
    if (response.statusCode == 404) throw Exception('Obavijest nije pronađena.');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GET $_newsPath/$id nije uspio: HTTP ${response.statusCode}');
    }
    final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
    return Announcement.fromNewsJson(map);
  }

  /// Updates an existing announcement by id.
  /// Returns the updated announcement.
  Future<Announcement> updateAnnouncement(
    int id, {
    required String title,
    required String body,
    AnnouncementType type = AnnouncementType.announcement,
  }) async {
    final Map<String, dynamic> bodyMap = <String, dynamic>{
      'title': title,
      'body': body,
    };
    final http.Response response = await _apiClient.put(
      '$_newsPath/$id',
      body: json.encode(bodyMap),
    );
    if (response.statusCode == 404) throw Exception('Obavijest nije pronađena.');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('PUT $_newsPath/$id nije uspio: HTTP ${response.statusCode}');
    }
    final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
    return Announcement.fromNewsJson(map);
  }

  /// Creates a new bag announcement via Announcements API.
  /// Returns the created announcement (refreshed from News).
  Future<Announcement> createBagAnnouncement({
    required String bagName,
    required double bagPrice,
    required String bagColor,
  }) async {
    const String path = '/api/Announcements/new-collection';
    final String title = 'Nova torbica: $bagName';
    final String body =
        'Predstavljamo vam novu torbicu "$bagName" u boji $bagColor po cijeni od ${bagPrice.toStringAsFixed(2)} KM. Pogledajte našu ponudu!';
    final Map<String, dynamic> bodyMap = <String, dynamic>{
      'subject': title,
      'body': body,
      'templateKey': '',
      'variables': <String, String>{'message': body},
      'segment': 'NewCollectionSubscribers',
      'productName': bagName,
      'price': bagPrice,
      'color': bagColor,
    };
    final http.Response response = await _apiClient.post(path, body: json.encode(bodyMap));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final List<Announcement> list = await getAnnouncements(page: 1, pageSize: 20);
    for (final Announcement announcement in list) {
      if (announcement.title == title && announcement.body == body) {
        return announcement;
      }
    }

    return Announcement(
      id: 0,
      title: title,
      body: body,
      publishedAt: DateTime.now(),
      type: AnnouncementType.announcement,
    );
  }
}
