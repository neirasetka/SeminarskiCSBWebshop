class Bag {
  const Bag({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.averageRating,
    this.code,
    this.bagTypeId,
    this.imageBase64,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final double? averageRating;
  final String? code;
  final int? bagTypeId;
  final String? imageBase64;

  String? get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (imageBase64 != null && imageBase64!.isNotEmpty) return 'data:image/png;base64,$imageBase64';
    return null;
  }

  factory Bag.fromJson(Map<String, dynamic> json) {
    return Bag(
      id: _toInt(json['BagID'] ?? json['bagID'] ?? json['ID'] ?? json['id'] ?? 0),
      name: (json['BagName'] ?? json['bagName'] ?? json['Name'] ?? json['name'] ?? '').toString(),
      description: (json['Description'] ?? json['description'] ?? '').toString(),
      price: _toDouble(json['Price'] ?? json['price'] ?? 0),
      imageUrl: (json['ImageUrl'] ?? json['imageUrl'])?.toString(),
      averageRating: _toNullableDouble(json['AverageRating'] ?? json['averageRating']),
      code: (json['Code'] ?? json['code'])?.toString(),
      bagTypeId: _toNullableInt(json['BagTypeID'] ?? json['bagTypeID']),
      imageBase64: (json['Image'] ?? json['image']) is String ? (json['Image'] ?? json['image']) as String : null,
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static double? _toNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

