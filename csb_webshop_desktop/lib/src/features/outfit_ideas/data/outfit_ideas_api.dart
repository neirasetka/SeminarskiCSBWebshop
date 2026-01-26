import 'dart:convert';
import 'dart:typed_data';

import '../../../core/api_client.dart';
import '../domain/outfit_idea.dart';

class OutfitIdeasApi {
  OutfitIdeasApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Gets all outfit ideas, optionally filtered by bagId or userId
  Future<List<OutfitIdea>> getAll({int? bagId, int? userId}) async {
    final List<String> params = <String>[];
    if (bagId != null) params.add('bagID=$bagId');
    if (userId != null) params.add('userID=$userId');
    
    final String queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _apiClient.get('/api/OutfitIdeas$queryString');
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
      return jsonList
          .map((dynamic e) => OutfitIdea.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load outfit ideas: ${response.statusCode}');
  }

  /// Gets an outfit idea by its ID
  Future<OutfitIdea> getById(int id) async {
    final response = await _apiClient.get('/api/OutfitIdeas/$id');
    
    if (response.statusCode == 200) {
      return OutfitIdea.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load outfit idea: ${response.statusCode}');
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
    throw Exception(
        'Failed to load outfit idea for bag: ${response.statusCode}');
  }

  /// Creates a new outfit idea
  Future<OutfitIdea> create({
    required int bagId,
    required int userId,
    String? title,
    String? description,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'bagID': bagId,
      'userID': userId,
      'title': title,
      'description': description,
    };

    final response =
        await _apiClient.post('/api/OutfitIdeas', body: json.encode(body));
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return OutfitIdea.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create outfit idea: ${response.statusCode}');
  }

  /// Updates an existing outfit idea
  Future<OutfitIdea> update(int id, {String? title, String? description}) async {
    final OutfitIdea existing = await getById(id);
    final Map<String, dynamic> body = <String, dynamic>{
      'bagID': existing.bagId,
      'userID': existing.userId,
      'title': title ?? existing.title,
      'description': description ?? existing.description,
    };

    final response =
        await _apiClient.put('/api/OutfitIdeas/$id', body: json.encode(body));
    
    if (response.statusCode == 200) {
      return OutfitIdea.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update outfit idea: ${response.statusCode}');
  }

  /// Deletes an outfit idea
  Future<void> delete(int id) async {
    final response = await _apiClient.delete('/api/OutfitIdeas/$id');
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete outfit idea: ${response.statusCode}');
    }
  }

  /// Adds an image to an outfit idea
  Future<OutfitIdeaImage> addImage({
    required int outfitIdeaId,
    required Uint8List imageBytes,
    String? caption,
    int displayOrder = 0,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'outfitIdeaID': outfitIdeaId,
      'image': imageBytes.toList(),
      'caption': caption,
      'displayOrder': displayOrder,
    };

    final response = await _apiClient.post(
      '/api/OutfitIdeas/$outfitIdeaId/images',
      body: json.encode(body),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return OutfitIdeaImage.fromJson(
          json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to add image: ${response.statusCode}');
  }

  /// Removes an image from an outfit idea
  Future<void> removeImage(int imageId) async {
    final response = await _apiClient.delete('/api/OutfitIdeas/images/$imageId');
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove image: ${response.statusCode}');
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
    throw Exception('Failed to load images: ${response.statusCode}');
  }
}
