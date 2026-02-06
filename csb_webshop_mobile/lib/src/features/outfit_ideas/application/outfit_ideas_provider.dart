import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_outfit_ideas_storage.dart';
import '../domain/outfit_idea.dart';

final Provider<LocalOutfitIdeasStorage> localOutfitIdeasStorageProvider =
    Provider<LocalOutfitIdeasStorage>((Ref ref) => LocalOutfitIdeasStorage());

/// Notifier for managing all outfit ideas.
class OutfitIdeasNotifier extends AsyncNotifier<Map<int, OutfitIdea>> {
  late final LocalOutfitIdeasStorage _storage;

  @override
  Future<Map<int, OutfitIdea>> build() async {
    _storage = ref.read(localOutfitIdeasStorageProvider);
    return _storage.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<Map<int, OutfitIdea>>();
    state = await AsyncValue.guard(() => _storage.getAll());
  }

  Future<void> addImages({
    required int bagId,
    required List<String> imagePaths,
  }) async {
    final Map<int, OutfitIdea> updated = await _storage.addImages(
      bagId: bagId,
      imagePaths: imagePaths,
    );
    state = AsyncData<Map<int, OutfitIdea>>(updated);
  }

  Future<void> removeImage({
    required int bagId,
    required String imagePath,
  }) async {
    final Map<int, OutfitIdea> updated = await _storage.removeImage(
      bagId: bagId,
      imagePath: imagePath,
    );
    state = AsyncData<Map<int, OutfitIdea>>(updated);
  }

  Future<void> saveOutfitIdea(OutfitIdea idea) async {
    final Map<int, OutfitIdea> updated = await _storage.saveForBag(idea);
    state = AsyncData<Map<int, OutfitIdea>>(updated);
  }

  Future<void> removeForBag(int bagId) async {
    final Map<int, OutfitIdea> updated = await _storage.removeForBag(bagId);
    state = AsyncData<Map<int, OutfitIdea>>(updated);
  }
}

final AsyncNotifierProvider<OutfitIdeasNotifier, Map<int, OutfitIdea>>
    outfitIdeasProvider =
    AsyncNotifierProvider<OutfitIdeasNotifier, Map<int, OutfitIdea>>(
        OutfitIdeasNotifier.new);

/// Provider to get outfit idea for a specific bag.
final outfitIdeaForBagProvider = Provider.autoDispose.family<OutfitIdea?, int>((ref, bagId) {
  final AsyncValue<Map<int, OutfitIdea>> allIdeas = ref.watch(outfitIdeasProvider);
  return allIdeas.value?[bagId];
});
