/// Model representing outfit inspiration images for a specific bag.
class OutfitIdea {
  OutfitIdea({
    required this.bagId,
    this.imagePaths = const <String>[],
  });

  /// The ID of the bag this outfit idea is associated with.
  final int bagId;

  /// List of local file paths for inspiration images.
  final List<String> imagePaths;

  /// Creates a copy with updated values.
  OutfitIdea copyWith({
    int? bagId,
    List<String>? imagePaths,
  }) {
    return OutfitIdea(
      bagId: bagId ?? this.bagId,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  /// Creates an OutfitIdea from JSON map.
  factory OutfitIdea.fromJson(Map<String, dynamic> json) {
    return OutfitIdea(
      bagId: json['bagId'] as int,
      imagePaths: (json['imagePaths'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          <String>[],
    );
  }

  /// Converts to JSON map for storage.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bagId': bagId,
      'imagePaths': imagePaths,
    };
  }
}
