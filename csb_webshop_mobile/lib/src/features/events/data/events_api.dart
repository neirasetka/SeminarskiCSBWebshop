import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/event.dart';

class EventsApi {
  EventsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _giveawaysPath = '/api/Giveaways';

  Future<List<EventModel>> getEvents() async {
    try {
      final http.Response response = await _apiClient.get('$_giveawaysPath?status=all');
      if (response.statusCode < 200 || response.statusCode >= 300) return List<EventModel>.from(_dummyEvents);
      final List<dynamic> items = json.decode(response.body) as List<dynamic>;
      return items
          .map((dynamic e) => _giveawayToEvent(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List<EventModel>.from(_dummyEvents);
    }
  }

  Future<EventModel> getEventById(int id) async {
    try {
      final http.Response response = await _apiClient.get('$_giveawaysPath/$id');
      if (response.statusCode == 404) throw Exception('Not found');
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return _giveawayToEvent(map);
    } catch (_) {
      final int idx = _dummyEvents.indexWhere((EventModel e) => e.id == id);
      if (idx >= 0) return _dummyEvents[idx];
      rethrow;
    }
  }

  /// Registers the current user as participant. Uses name and email for Giveaways API.
  Future<EventModel> participate({
    required int eventId,
    required String name,
    required String email,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'name': name,
        'email': email,
      };
      final http.Response response = await _apiClient.post(
        '$_giveawaysPath/$eventId/participants',
        body: json.encode(body),
      );
      if (response.statusCode == 404) throw Exception('Not found');
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
      final EventModel event = await getEventById(eventId);
      return event.copyWith(isParticipating: true);
    } catch (_) {
      final int idx = _dummyEvents.indexWhere((EventModel e) => e.id == eventId);
      if (idx >= 0) {
        final EventModel current = _dummyEvents[idx];
        return current.copyWith(isParticipating: true);
      }
      rethrow;
    }
  }
}

final List<EventModel> _dummyEvents = <EventModel>[
  EventModel(
    id: 1,
    title: 'Giveaway – CSB torba',
    description: 'Prijavi se i osvoji limited edition CSB torbu! Izvlačenje na početku eventa.',
    startDateTime: DateTime.now().add(const Duration(minutes: 10)),
    participants: <int>[],
  ),
  EventModel(
    id: 2,
    title: 'Live Q&A',
    description: 'Postavite pitanja uživo. Najbolje pitanje dobija poklon vaučer.',
    startDateTime: DateTime.now().add(const Duration(hours: 3)),
    participants: <int>[],
  ),
];

EventModel _giveawayToEvent(Map<String, dynamic> json) {
  final int id = _toInt(json['id'] ?? json['Id']);
  final String title = (json['title'] ?? json['Title'] ?? '') as String;
  final String? endDateRaw = (json['endDate'] ?? json['EndDate']) as String?;
  final String? startDateRaw = (json['startDate'] ?? json['StartDate']) as String?;
  final DateTime startDate = startDateRaw != null ? DateTime.parse(startDateRaw) : DateTime.now();
  final String description = endDateRaw != null
      ? 'Prijava je otvorena do ${DateTime.parse(endDateRaw).toLocal()}'
      : 'Giveaway događaj';
  return EventModel(
    id: id,
    title: title,
    description: description,
    startDateTime: startDate,
    participants: null,
    isParticipating: false,
  );
}

int _toInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}
