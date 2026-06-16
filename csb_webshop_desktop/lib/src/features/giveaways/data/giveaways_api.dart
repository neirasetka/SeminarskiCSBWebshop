import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
import '../../../core/api_error_reader.dart';
import '../../../core/paged_result.dart';
import '../domain/giveaway.dart';
import '../domain/participant.dart';

/// Thrown when the same email is already registered for this giveaway (HTTP 409).
class GiveawayRegistrationConflictException implements Exception {
  GiveawayRegistrationConflictException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Parses API error JSON (`message`, `error`, or RFC 7807 `detail`).
String? giveawayApiMessageFromJsonBody(String body) {
  if (body.trim().isEmpty) return null;
  final String detail = ApiErrorReader.readDetail(body, fallback: '');
  if (detail.isEmpty || detail == '(prazan odgovor)') return null;
  return detail;
}

class GiveawaysApi {
  GiveawaysApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _basePath = '/api/Giveaways';

  Future<List<Giveaway>> getGiveaways({
    String status = 'all',
    int pageSize = 100,
  }) async {
    return PagedResult.collectAllPages<Giveaway>(
      pageSize: pageSize,
      fetchPage: (int page, int psz) async {
        final String statusQuery = status.isEmpty || status == 'all' ? '' : 'status=$status&';
        final http.Response response = await _apiClient.get(
          '$_basePath?${statusQuery}page=$page&pageSize=$psz',
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
          return PagedResult.fromJson(map, (Map<String, dynamic> e) => Giveaway.fromJson(e));
        }
        throw Exception('Failed to load giveaways: ${response.statusCode}');
      },
    );
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

  Future<Giveaway> updateGiveawayDuration({
    required int giveawayId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'StartDate': startDate.toUtc().toIso8601String(),
      'EndDate': endDate.toUtc().toIso8601String(),
    };
    final http.Response response = await _apiClient.put('$_basePath/$giveawayId/duration', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return Giveaway.fromJson(map);
    }
    final String? apiMessage = giveawayApiMessageFromJsonBody(response.body);
    throw Exception(apiMessage ?? 'Failed to update giveaway duration: ${response.statusCode}');
  }

  Future<List<GiveawayParticipant>> getParticipants(
    int giveawayId, {
    int pageSize = 100,
  }) async {
    return PagedResult.collectAllPages<GiveawayParticipant>(
      pageSize: pageSize,
      fetchPage: (int page, int psz) async {
        final http.Response response = await _apiClient.get(
          '$_basePath/$giveawayId/participants?page=$page&pageSize=$psz',
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
          return PagedResult.fromJson(
            map,
            (Map<String, dynamic> e) => GiveawayParticipant.fromAdminJson(e),
          );
        }
        throw Exception('Failed to load participants: ${response.statusCode}');
      },
    );
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
    if (response.statusCode == 409) {
      throw GiveawayRegistrationConflictException(
        giveawayApiMessageFromJsonBody(response.body) ?? 'Već učestvujete u giveawayu.',
      );
    }
    throw Exception('Failed to register: ${response.statusCode}');
  }

  Future<GiveawayParticipant> drawWinner(int giveawayId) async {
    final http.Response response = await _apiClient.post('$_basePath/$giveawayId/draw');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return GiveawayParticipant.fromAdminJson(map);
    }
    final String? apiMessage = giveawayApiMessageFromJsonBody(response.body);
    throw Exception(apiMessage ?? 'Failed to draw winner: ${response.statusCode}');
  }

  Future<void> notifyWinner(int giveawayId) async {
    final http.Response response = await _apiClient.post('/api/Participants/$giveawayId/notify-winner');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final String? apiMessage = giveawayApiMessageFromJsonBody(response.body);
    throw Exception(apiMessage ?? 'Failed to notify winner: ${response.statusCode}');
  }

  /// Announces the giveaway winner by:
  /// 1. Posting to info panel (news)
  /// 2. Sending email to winner
  /// 3. Sending email to giveaway newsletter subscribers
  Future<AnnounceWinnerResult> announceWinner(int giveawayId) async {
    final http.Response response = await _apiClient.post('$_basePath/$giveawayId/announce-winner');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return AnnounceWinnerResult.fromJson(map);
    }
    final String? apiMessage = giveawayApiMessageFromJsonBody(response.body);
    throw Exception(apiMessage ?? 'Failed to announce winner: ${response.statusCode}');
  }
}

class AnnounceWinnerResult {
  AnnounceWinnerResult({
    required this.message,
    this.winnerName,
    required this.subscribersNotified,
    this.newsItemId,
  });

  factory AnnounceWinnerResult.fromJson(Map<String, dynamic> json) {
    return AnnounceWinnerResult(
      message: json['message'] as String? ?? 'Success',
      winnerName: json['winnerName'] as String?,
      subscribersNotified: json['subscribersNotified'] as int? ?? 0,
      newsItemId: json['newsItemId'] as int?,
    );
  }

  final String message;
  final String? winnerName;
  final int subscribersNotified;
  final int? newsItemId;
}

