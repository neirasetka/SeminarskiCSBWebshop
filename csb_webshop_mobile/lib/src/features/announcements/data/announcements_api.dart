import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/announcement.dart';

class AnnouncementsApi {
  AnnouncementsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _newsPath = '/api/News';
  static const String _newCollectionPath = '/api/Announcements/new-collection';

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
      _ensureSuccess(response, 'load announcements');
      final List<dynamic> items = json.decode(response.body) as List<dynamic>;
      return items.map((dynamic e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
    } catch (Object error, StackTrace stackTrace) {
      developer.log(
        'Falling back to demo announcements',
        name: 'AnnouncementsApi',
        error: error,
        stackTrace: stackTrace,
      );
      return _demoAnnouncementsSnapshot();
    }
  }

  Future<Announcement> getAnnouncementById(int id) async {
    try {
      final http.Response response = await _apiClient.get('$_newsPath/$id');
      _ensureSuccess(response, 'load announcement $id');
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Announcement.fromJson(map);
    } catch (Object error, StackTrace stackTrace) {
      final Announcement? fallback = _findDemoAnnouncement(id);
      if (fallback != null) {
        developer.log(
          'Serving announcement $id from demo cache',
          name: 'AnnouncementsApi',
          error: error,
          stackTrace: stackTrace,
        );
        return fallback;
      }
      rethrow;
    }
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

    try {
      final http.Response response = await _apiClient.post(_newCollectionPath, body: json.encode(body));
      _ensureSuccess(response, 'create announcement');
    } catch (Object error, StackTrace stackTrace) {
      developer.log(
        'Failed to create announcement remotely, adding demo entry instead',
        name: 'AnnouncementsApi',
        error: error,
        stackTrace: stackTrace,
      );
      _addDemoAnnouncement(
        title: 'Nova torbica: $bagName',
        body: 'Model $bagName upravo je dodan u kolekciju u $color boji po cijeni ${_formatPrice(price)} KM.',
        type: AnnouncementType.announcement,
        segment: 'NewCollectionSubscribers',
        productName: bagName,
        price: price,
        color: color,
      );
    }
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

List<Announcement> _demoAnnouncementsSnapshot() => List<Announcement>.unmodifiable(_demoAnnouncements);

Announcement? _findDemoAnnouncement(int id) {
  for (final Announcement announcement in _demoAnnouncements) {
    if (announcement.id == id) {
      return announcement;
    }
  }
  return null;
}

void _addDemoAnnouncement({
  required String title,
  required String body,
  required AnnouncementType type,
  required String segment,
  String? productName,
  double? price,
  String? color,
}) {
  final Announcement announcement = Announcement(
    id: _nextDemoAnnouncementId++,
    title: title,
    body: body,
    publishedAt: DateTime.now(),
    type: type,
    segment: segment,
    productName: productName,
    price: price,
    color: color,
    launchDate: DateTime.now(),
  );
  _demoAnnouncements.insert(0, announcement);
}

final List<Announcement> _demoAnnouncements = <Announcement>[
  Announcement(
    id: 1001,
    title: 'Danas izlazi nova torbica LEA',
    body: 'LEA model stiže večeras u 20:00h u tri limited boje. Količina je ograničena pa pripremi wishlistu.',
    publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
    type: AnnouncementType.announcement,
    segment: 'NewCollectionSubscribers',
    launchDate: DateTime.now(),
    productName: 'LEA',
    price: 189,
    color: 'Midnight Blue',
  ),
  Announcement(
    id: 1002,
    title: 'Giveaway traje još 2 dana',
    body: 'Podsjetnik: prijave se zatvaraju u petak u 18:00h. Uključi se i osvoji komplet accessories set.',
    publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
    type: AnnouncementType.info,
    segment: 'GiveawaySubscribers',
  ),
  Announcement(
    id: 1003,
    title: 'Novi lookbook za prosinac',
    body: 'Lookbook je osvježen zimskim kombinacijama i behind-the-scenes fotkama s posljednjeg snimanja.',
    publishedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    type: AnnouncementType.update,
    segment: 'AllSubscribers',
  ),
];

int _nextDemoAnnouncementId = 1004;

