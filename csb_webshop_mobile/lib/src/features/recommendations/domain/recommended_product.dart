/// Backend [RecommendedProductDto] — content-based preporuka sa objašnjenjem.
class RecommendedProduct {
  const RecommendedProduct({
    required this.productId,
    required this.productName,
    required this.productType,
    required this.description,
    required this.price,
    required this.score,
    required this.reason,
    required this.isPersonalized,
    this.imageBase64,
  });

  final int productId;
  final String productName;
  final String productType;
  final String description;
  final double price;
  final double score;
  final String reason;
  final bool isPersonalized;
  final String? imageBase64;

  bool get isBag => productType.toLowerCase() == 'bag';

  String? get displayImageUrl {
    if (imageBase64 == null || imageBase64!.isEmpty) return null;
    if (imageBase64!.startsWith('data:image')) return imageBase64;
    return 'data:image/png;base64,$imageBase64';
  }

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) {
    return RecommendedProduct(
      productId: _toInt(json['productId'] ?? json['ProductId']),
      productName: (json['productName'] ?? json['ProductName'] ?? '').toString(),
      productType: (json['productType'] ?? json['ProductType'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      price: _toDouble(json['price'] ?? json['Price']),
      score: _toDouble(json['score'] ?? json['Score']),
      reason: (json['reason'] ?? json['Reason'] ?? '').toString(),
      isPersonalized: json['isPersonalized'] == true || json['IsPersonalized'] == true,
      imageBase64: _imageToBase64(json['image'] ?? json['Image']),
    );
  }

  static String? _imageToBase64(Object? value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
