/// Model representing outfit inspiration for a specific bag.
class OutfitIdea {
  OutfitIdea({
    required this.outfitIdeaId,
    required this.bagId,
    required this.userId,
    this.title,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.images = const <OutfitIdeaImage>[],
  });

  final int outfitIdeaId;
  final int bagId;
  final int userId;
  final String? title;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OutfitIdeaImage> images;

  factory OutfitIdea.fromJson(Map<String, dynamic> json) {
    return OutfitIdea(
      outfitIdeaId: json['outfitIdeaID'] as int? ?? 0,
      bagId: json['bagID'] as int? ?? 0,
      userId: json['userID'] as int? ?? 0,
      title: json['title'] as String?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  OutfitIdeaImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <OutfitIdeaImage>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'outfitIdeaID': outfitIdeaId,
      'bagID': bagId,
      'userID': userId,
      'title': title,
      'description': description,
    };
  }

  OutfitIdea copyWith({
    int? outfitIdeaId,
    int? bagId,
    int? userId,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OutfitIdeaImage>? images,
  }) {
    return OutfitIdea(
      outfitIdeaId: outfitIdeaId ?? this.outfitIdeaId,
      bagId: bagId ?? this.bagId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
    );
  }
}

/// Model representing an inspiration image within an outfit idea.
class OutfitIdeaImage {
  OutfitIdeaImage({
    required this.outfitIdeaImageId,
    required this.outfitIdeaId,
    this.imageBytes,
    this.caption,
    this.displayOrder = 0,
    this.createdAt,
  });

  final int outfitIdeaImageId;
  final int outfitIdeaId;
  final List<int>? imageBytes;
  final String? caption;
  final int displayOrder;
  final DateTime? createdAt;

  factory OutfitIdeaImage.fromJson(Map<String, dynamic> json) {
    List<int>? bytes;
    if (json['image'] != null) {
      if (json['image'] is List) {
        bytes = (json['image'] as List<dynamic>).cast<int>();
      } else if (json['image'] is String) {
        // Handle base64 encoded string if needed
        bytes = null;
      }
    }

    return OutfitIdeaImage(
      outfitIdeaImageId: json['outfitIdeaImageID'] as int? ?? 0,
      outfitIdeaId: json['outfitIdeaID'] as int? ?? 0,
      imageBytes: bytes,
      caption: json['caption'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'outfitIdeaImageID': outfitIdeaImageId,
      'outfitIdeaID': outfitIdeaId,
      'image': imageBytes,
      'caption': caption,
      'displayOrder': displayOrder,
    };
  }
}
