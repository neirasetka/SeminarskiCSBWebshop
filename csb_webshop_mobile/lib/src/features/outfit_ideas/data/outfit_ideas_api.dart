import 'dart:convert';
import 'dart:typed_data';

import '../../../core/api_client.dart';
import '../../../core/api_error_reader.dart';
import '../../../core/paged_result.dart';
import '../domain/outfit_idea.dart';

class OutfitIdeasApi {
  OutfitIdeasApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<OutfitIdea>> getAll({int? bagId, int? beltId, int? userId, int page = 1, int pageSize = 20}) async {
    final List<String> params = <String>[
      'page=$page',
      'pageSize=$pageSize',
    ];
    if (bagId != null) params.add('bagID=$bagId');
    if (beltId != null) params.add('beltID=$beltId');
    if (userId != null) params.add('userID=$userId');
    final String queryString = '?${params.join('&')}';

    final response = await _apiClient.get('/api/OutfitIdeas/search$queryString');
    if (response.statusCode == 200) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return PagedResult.fromJson(map, OutfitIdea.fromJson).items;
    }

    throw Exception(_buildError(response, 'Failed to load outfit ideas'));
  }

  Future<OutfitIdea> getById(int id) async {
    final response = await _apiClient.get('/api/OutfitIdeas/$id');
    if (response.statusCode == 200) {
      return OutfitIdea.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_buildError(response, 'Failed to load outfit idea'));
  }

  Future<OutfitIdea> createForBag({
    required int bagId,
    required int userId,
    String? title,
    String? description,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'BagID': bagId,
      'UserID': userId,
      'Title': title ?? 'Outfit inspiracija',
      'Description': description ?? '',
    };

    final response =
        await _apiClient.post('/api/OutfitIdeas', body: json.encode(body));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return OutfitIdea.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_buildError(response, 'Failed to create outfit idea'));
  }

  Future<OutfitIdeaImage> addImage({
    required int outfitIdeaId,
    required Uint8List imageBytes,
    String? caption,
    int displayOrder = 0,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'OutfitIdeaID': outfitIdeaId,
      'Image': base64Encode(imageBytes),
      'Caption': caption,
      'DisplayOrder': displayOrder,
    };

    final response = await _apiClient.post(
      '/api/OutfitIdeas/$outfitIdeaId/images',
      body: json.encode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return OutfitIdeaImage.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception(_buildError(response, 'Failed to add image'));
  }

  Future<void> removeImage(int imageId) async {
    final response = await _apiClient.delete('/api/OutfitIdeas/images/$imageId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_buildError(response, 'Failed to remove image'));
    }
  }

  static String _buildError(dynamic response, String fallback) {
    final String detail = ApiErrorReader.readDetail(response.body?.toString() ?? '');
    if (detail.isNotEmpty && detail != '(prazan odgovor)') {
      return detail;
    }
    return '$fallback (${response.statusCode})';
  }
}
