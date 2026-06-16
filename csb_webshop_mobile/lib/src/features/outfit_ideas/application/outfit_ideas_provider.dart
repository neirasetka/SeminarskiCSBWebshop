import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_exception.dart';
import '../data/outfit_ideas_api.dart';
import '../domain/outfit_idea.dart';

final Provider<OutfitIdeasApi> outfitIdeasApiProvider =
    Provider<OutfitIdeasApi>((Ref ref) => OutfitIdeasApi());

class OutfitIdeaState {
  OutfitIdeaState({
    this.outfitIdea,
    this.isLoading = false,
    this.error,
  });

  final OutfitIdea? outfitIdea;
  final bool isLoading;
  final String? error;

  OutfitIdeaState copyWith({
    OutfitIdea? outfitIdea,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearOutfitIdea = false,
  }) {
    return OutfitIdeaState(
      outfitIdea: clearOutfitIdea ? null : (outfitIdea ?? this.outfitIdea),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OutfitIdeaNotifier extends StateNotifier<OutfitIdeaState> {
  OutfitIdeaNotifier(this._api) : super(OutfitIdeaState());

  final OutfitIdeasApi _api;

  Future<void> loadForBag(int bagId, int? userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final List<OutfitIdea> ideas = await _api.getAll(bagId: bagId);
      OutfitIdea? idea;
      if (userId != null) {
        idea = ideas
                .where((OutfitIdea o) => o.userId == userId)
                .where((OutfitIdea o) => o.images.isNotEmpty)
                .firstOrNull ??
            ideas.where((OutfitIdea o) => o.userId == userId).firstOrNull;
      }
      idea ??= ideas
              .where((OutfitIdea o) => o.images.isNotEmpty)
              .firstOrNull ??
          ideas.firstOrNull;
      state = state.copyWith(
        outfitIdea: idea,
        isLoading: false,
        clearOutfitIdea: idea == null,
      );
    } catch (e) {
      state = state.copyWith(error: ApiException.formatForDisplay(e), isLoading: false);
    }
  }

  Future<OutfitIdea?> createOutfitIdea({
    required int bagId,
    required int userId,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final OutfitIdea idea = await _api.createForBag(
        bagId: bagId,
        userId: userId,
        title: title,
        description: description,
      );
      state = state.copyWith(outfitIdea: idea, isLoading: false);
      return idea;
    } catch (e) {
      state = state.copyWith(error: ApiException.formatForDisplay(e), isLoading: false);
      return null;
    }
  }

  Future<bool> addImage(Uint8List imageBytes, {String? caption}) async {
    final OutfitIdea? current = state.outfitIdea;
    if (current == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final OutfitIdeaImage newImage = await _api.addImage(
        outfitIdeaId: current.outfitIdeaId,
        imageBytes: imageBytes,
        caption: caption,
        displayOrder: current.images.length,
      );

      state = state.copyWith(
        outfitIdea: current.copyWith(
          images: <OutfitIdeaImage>[...current.images, newImage],
        ),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiException.formatForDisplay(e), isLoading: false);
      return false;
    }
  }

  Future<bool> removeImage(int imageId) async {
    final OutfitIdea? current = state.outfitIdea;
    if (current == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.removeImage(imageId);
      state = state.copyWith(
        outfitIdea: current.copyWith(
          images: current.images
              .where((OutfitIdeaImage img) => img.outfitIdeaImageId != imageId)
              .toList(),
        ),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiException.formatForDisplay(e), isLoading: false);
      return false;
    }
  }

  void clear() {
    state = OutfitIdeaState();
  }
}

final StateNotifierProvider<OutfitIdeaNotifier, OutfitIdeaState>
    outfitIdeaProvider = StateNotifierProvider<OutfitIdeaNotifier, OutfitIdeaState>(
  (Ref ref) => OutfitIdeaNotifier(ref.read(outfitIdeasApiProvider)),
);
