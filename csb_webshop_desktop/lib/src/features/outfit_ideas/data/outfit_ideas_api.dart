import 'dart:convert';
import 'dart:typed_data';

import '../../../core/api_client.dart';
import '../../../core/api_error_reader.dart';
import '../../../core/paged_result.dart';
import '../domain/outfit_idea.dart';

class OutfitIdeasApi {
  OutfitIdeasApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Gets all outfit ideas, optionally filtered by bagId, beltId or userId.
  /// Uses /search endpoint to avoid backend model binding issues.
  Future<List<OutfitIdea>> getAll({int? bagId, int? beltId, int? userId}) async {
    final List<String> params = <String>[];
    if (bagId != null) params.add('bagID=$bagId');
    if (beltId != null) params.add('beltID=$beltId');
    if (userId != null) params.add('userID=$userId');
    params.add('pageSize=100');

    final String queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _apiClient.get('/api/OutfitIdeas/search$queryString');

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is List<dynamic>) {
        return decoded
            .map((dynamic e) => OutfitIdea.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (decoded is Map<String, dynamic>) {
        return PagedResult.fromJson(decoded, OutfitIdea.fromJson).items;
      }
      return <OutfitIdea>[];
    }
    throw Exception(_parseError(response, 'Failed to load outfit ideas'));
  }

  /// Gets an outfit idea by its ID
  Future<OutfitIdea> getById(int id) async {
    final response = await _apiClient.get('/api/OutfitIdeas/$id');
    
    if (response.statusCode == 200) {
      return OutfitIdea.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_parseError(response, 'Failed to load outfit idea'));
  }

  /// Gets outfit idea for a specific bag and user
  Future<OutfitIdea?> getByBagAndUser(int bagId, int userId) async {
    final response =
        await _apiClient.get('/api/OutfitIdeas/bag/$bagId/user/$userId');
    
    if (response.statusCode == 200) {
      return OutfitIdea.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception(_parseError(response, 'Failed to load outfit idea for bag'));
  }

  /// Gets outfit idea for a specific belt and user
  Future<OutfitIdea?> getByBeltAndUser(int beltId, int userId) async {
    final response =
        await _apiClient.get('/api/OutfitIdeas/belt/$beltId/user/$userId');
    
    if (response.statusCode == 200) {
      return OutfitIdea.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception(_parseError(response, 'Failed to load outfit idea for belt'));
  }

  /// Creates a new outfit idea for a bag
  Future<OutfitIdea> createForBag({
    required int bagId,
    required int userId,
    String? title,
    String? description,
  }) async {
    // Backend expects PascalCase; omit beltID for bag outfit ideas
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
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_parseError(response, 'Failed to create outfit idea'));
  }

  /// Creates a new outfit idea for a belt
  Future<OutfitIdea> createForBelt({
    required int beltId,
    required int userId,
    String? title,
    String? description,
  }) async {
    // Backend expects PascalCase; omit bagID for belt outfit ideas
    final Map<String, dynamic> body = <String, dynamic>{
      'BeltID': beltId,
      'UserID': userId,
      'Title': title ?? 'Outfit inspiracija',
      'Description': description ?? '',
    };

    final response =
        await _apiClient.post('/api/OutfitIdeas', body: json.encode(body));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return OutfitIdea.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_parseError(response, 'Failed to create outfit idea'));
  }

  static String _parseError(dynamic response, String fallback) {
    final String detail = ApiErrorReader.readDetail(response.body?.toString() ?? '');
    if (detail.isNotEmpty && detail != '(prazan odgovor)') {
      return detail;
    }
    return '$fallback (${response.statusCode})';
  }

  /// Updates an existing outfit idea
  Future<OutfitIdea> update(int id, {String? title, String? description}) async {
    final OutfitIdea existing = await getById(id);
    final Map<String, dynamic> body = <String, dynamic>{
      'BagID': existing.bagId,
      'BeltID': existing.beltId,
      'UserID': existing.userId,
      'Title': title ?? existing.title,
      'Description': description ?? existing.description,
    };

    final response =
        await _apiClient.put('/api/OutfitIdeas/$id', body: json.encode(body));
    
    if (response.statusCode == 200) {
      return OutfitIdea.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_parseError(response, 'Failed to update outfit idea'));
  }

  /// Deletes an outfit idea
  Future<void> delete(int id) async {
    final response = await _apiClient.delete('/api/OutfitIdeas/$id');
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_parseError(response, 'Failed to delete outfit idea'));
    }
  }

  /// Adds an image to an outfit idea
  Future<OutfitIdeaImage> addImage({
    required int outfitIdeaId,
    required Uint8List imageBytes,
    String? caption,
    int displayOrder = 0,
  }) async {
    final String imageBase64 = base64Encode(imageBytes);
    final Map<String, dynamic> body = <String, dynamic>{
      'OutfitIdeaID': outfitIdeaId,
      'Image': imageBase64,
      'Caption': caption,
      'DisplayOrder': displayOrder,
    };

    final response = await _apiClient.post(
      '/api/OutfitIdeas/$outfitIdeaId/images',
      body: json.encode(body),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return OutfitIdeaImage.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception(_parseError(response, 'Failed to add image'));
  }

  /// Removes an image from an outfit idea
  Future<void> removeImage(int imageId) async {
    final response = await _apiClient.delete('/api/OutfitIdeas/images/$imageId');
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_parseError(response, 'Failed to remove image'));
    }
  }

  /// Gets all images for an outfit idea
  Future<List<OutfitIdeaImage>> getImages(int outfitIdeaId) async {
    final response =
        await _apiClient.get('/api/OutfitIdeas/$outfitIdeaId/images');
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
      return jsonList
          .map((dynamic e) =>
              OutfitIdeaImage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_parseError(response, 'Failed to load images'));
  }
}
