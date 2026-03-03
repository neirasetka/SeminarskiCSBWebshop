import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/announcement.dart';

class AnnouncementsApi {
  AnnouncementsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _newsPath = '/api/News';

  Future<List<Announcement>> getAnnouncements({int page = 1, int pageSize = 20, String? segment}) async {
    try {
      final Map<String, String> params = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
        if (segment != null && segment.isNotEmpty) 'segment': segment,
      };
      final String query = Uri(queryParameters: params).query;
      final String path = query.isEmpty ? _newsPath : '$_newsPath?$query';
      final http.Response response = await _apiClient.get(path);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return List<Announcement>.from(_dummyAnnouncements);
      }
      final List<dynamic> items = json.decode(response.body) as List<dynamic>;
      return items
          .map((dynamic e) => Announcement.fromNewsJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List<Announcement>.from(_dummyAnnouncements);
    }
  }

  Future<Announcement> getAnnouncementById(int id) async {
    try {
      final http.Response response = await _apiClient.get('$_newsPath/$id');
      if (response.statusCode == 404) throw Exception('Not found');
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Announcement.fromNewsJson(map);
    } catch (_) {
      final int idx = _dummyAnnouncements.indexWhere((Announcement a) => a.id == id);
      if (idx >= 0) return _dummyAnnouncements[idx];
      rethrow;
    }
  }

  /// Updates an existing announcement by id.
  /// Returns the updated announcement.
  Future<Announcement> updateAnnouncement(
    int id, {
    required String title,
    required String body,
    AnnouncementType type = AnnouncementType.announcement,
  }) async {
    try {
      final Map<String, dynamic> bodyMap = <String, dynamic>{
        'title': title,
        'body': body,
      };
      final http.Response response = await _apiClient.put(
        '$_newsPath/$id',
        body: json.encode(bodyMap),
      );
      if (response.statusCode == 404) throw Exception('Not found');
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Announcement.fromNewsJson(map);
    } catch (_) {
      final int idx = _dummyAnnouncements.indexWhere((Announcement a) => a.id == id);
      if (idx < 0) rethrow;
      final Announcement existing = _dummyAnnouncements[idx];
      final Announcement updated = Announcement(
        id: existing.id,
        title: title,
        body: body,
        publishedAt: existing.publishedAt,
        type: type,
      );
      _dummyAnnouncements[idx] = updated;
      return updated;
    }
  }

  /// Creates a new bag announcement via Announcements API.
  /// Returns the created announcement (refreshed from News or dummy).
  Future<Announcement> createBagAnnouncement({
    required String bagName,
    required double bagPrice,
    required String bagColor,
  }) async {
    try {
      const String path = '/api/Announcements/new-collection';
      final Map<String, dynamic> bodyMap = <String, dynamic>{
        'subject': 'Nova torbica: $bagName',
        'body': 'Predstavljamo vam novu torbicu "$bagName" u boji $bagColor po cijeni od ${bagPrice.toStringAsFixed(2)} KM. Pogledajte našu ponudu!',
        'segment': 'NewCollectionSubscribers',
        'productName': bagName,
        'price': bagPrice,
        'color': bagColor,
      };
      final http.Response response = await _apiClient.post(path, body: json.encode(bodyMap));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      final List<Announcement> list = await getAnnouncements(page: 1, pageSize: 1);
      if (list.isNotEmpty) return list.first;
    } catch (_) {
      // fallback to dummy
    }
    final int newId = _dummyAnnouncements.isEmpty
        ? 1
        : _dummyAnnouncements.map((Announcement a) => a.id).reduce((int a, int b) => a > b ? a : b) + 1;
    final Announcement newAnnouncement = Announcement(
      id: newId,
      title: 'Nova torbica: $bagName',
      body: 'Predstavljamo vam novu torbicu "$bagName" u boji $bagColor po cijeni od ${bagPrice.toStringAsFixed(2)} KM. Pogledajte našu ponudu!',
      publishedAt: DateTime.now(),
      type: AnnouncementType.announcement,
    );
    _dummyAnnouncements.insert(0, newAnnouncement);
    return newAnnouncement;
  }
}

final List<Announcement> _dummyAnnouncements = <Announcement>[
  Announcement(
    id: 1,
    title: 'Dobrodošli na CocoSunBags Webshop',
    body: 'Hvala što koristite našu aplikaciju. Ovo je početna obavijest.',
    publishedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    type: AnnouncementType.info,
  ),
  Announcement(
    id: 2,
    title: 'Veliki update 1.1',
    body: 'Dodali smo nove funkcionalnosti i poboljšanja performansi.',
    publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
    type: AnnouncementType.update,
  ),
  Announcement(
    id: 3,
    title: 'Akcija ovog vikenda',
    body: 'Iskoristite posebne popuste do 30% na odabrane artikle.',
    publishedAt: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
    type: AnnouncementType.announcement,
  ),
];
