import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../domain/giveaway.dart';
import '../domain/participant.dart';

class GiveawaysApi {
  GiveawaysApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _basePath = '/api/Giveaways';

  Future<List<Giveaway>> getGiveaways({String status = 'all'}) async {
    final String path = status.isEmpty || status == 'all' ? _basePath : '$_basePath?status=$status';
    final http.Response response = await _apiClient.get(path);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => Giveaway.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load giveaways: ${response.statusCode}');
  }

  Future<Giveaway> createGiveaway({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'Title': title,
      'StartDate': startDate.toUtc().toIso8601String(),
      'EndDate': endDate.toUtc().toIso8601String(),
    };
    final http.Response response = await _apiClient.post(_basePath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Giveaway.fromJson(map);
    }
    throw Exception('Failed to create giveaway: ${response.statusCode}');
  }

  Future<List<GiveawayParticipant>> getParticipants(int giveawayId) async {
    final http.Response response = await _apiClient.get('$_basePath/$giveawayId/participants');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> list = json.decode(response.body) as List<dynamic>;
      return list.map((dynamic e) => GiveawayParticipant.fromAdminJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load participants: ${response.statusCode}');
  }

  Future<GiveawayParticipant> registerParticipant({
    required int giveawayId,
    String? name,
    required String email,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      if (name != null) 'Name': name,
      'Email': email,
    };
    final http.Response response = await _apiClient.post('$_basePath/$giveawayId/participants', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return GiveawayParticipant.fromPublicJson(map);
    }
    throw Exception('Failed to register: ${response.statusCode}');
  }

  Future<GiveawayParticipant> drawWinner(int giveawayId) async {
    final http.Response response = await _apiClient.post('$_basePath/$giveawayId/draw');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return GiveawayParticipant.fromAdminJson(map);
    }
    throw Exception('Failed to draw winner: ${response.statusCode}');
  }

  Future<void> notifyWinner(int giveawayId) async {
    final http.Response response = await _apiClient.post('/api/Participants/$giveawayId/notify-winner');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to notify winner: ${response.statusCode}');
  }
}

