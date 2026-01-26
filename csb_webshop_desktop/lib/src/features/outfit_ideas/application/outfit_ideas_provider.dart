import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/outfit_ideas_api.dart';
import '../domain/outfit_idea.dart';

final Provider<OutfitIdeasApi> outfitIdeasApiProvider =
    Provider<OutfitIdeasApi>((Ref ref) => OutfitIdeasApi());

/// State for the outfit idea detail view
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

/// Notifier for managing a single outfit idea for a bag
class OutfitIdeaNotifier extends StateNotifier<OutfitIdeaState> {
  OutfitIdeaNotifier(this._api) : super(OutfitIdeaState());

  final OutfitIdeasApi _api;

  /// Loads outfit idea for a specific bag and user
  Future<void> loadForBag(int bagId, int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final OutfitIdea? idea = await _api.getByBagAndUser(bagId, userId);
      state = state.copyWith(outfitIdea: idea, isLoading: false, clearOutfitIdea: idea == null);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Creates a new outfit idea for the bag
  Future<OutfitIdea?> createOutfitIdea({
    required int bagId,
    required int userId,
    String? title,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final OutfitIdea idea = await _api.create(
        bagId: bagId,
        userId: userId,
        title: title,
        description: description,
      );
      state = state.copyWith(outfitIdea: idea, isLoading: false);
      return idea;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return null;
    }
  }

  /// Adds an image to the current outfit idea
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

      // Update local state with new image
      final List<OutfitIdeaImage> updatedImages = <OutfitIdeaImage>[
        ...current.images,
        newImage,
      ];
      state = state.copyWith(
        outfitIdea: current.copyWith(images: updatedImages),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Removes an image from the current outfit idea
  Future<bool> removeImage(int imageId) async {
    final OutfitIdea? current = state.outfitIdea;
    if (current == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.removeImage(imageId);

      // Update local state
      final List<OutfitIdeaImage> updatedImages = current.images
          .where((OutfitIdeaImage img) => img.outfitIdeaImageId != imageId)
          .toList();
      state = state.copyWith(
        outfitIdea: current.copyWith(images: updatedImages),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Refreshes the current outfit idea
  Future<void> refresh() async {
    final OutfitIdea? current = state.outfitIdea;
    if (current == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final OutfitIdea idea = await _api.getById(current.outfitIdeaId);
      state = state.copyWith(outfitIdea: idea, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Clears the current state
  void clear() {
    state = OutfitIdeaState();
  }
}

final StateNotifierProvider<OutfitIdeaNotifier, OutfitIdeaState>
    outfitIdeaProvider =
    StateNotifierProvider<OutfitIdeaNotifier, OutfitIdeaState>(
  (Ref ref) => OutfitIdeaNotifier(ref.read(outfitIdeasApiProvider)),
);
