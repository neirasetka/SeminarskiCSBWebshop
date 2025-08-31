class Belt {
  const Belt({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.averageRating,
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final double? averageRating;

  factory Belt.fromJson(Map<String, dynamic> json) {
    return Belt(
      id: _toInt(json['BeltID'] ?? json['beltID'] ?? json['ID'] ?? json['id'] ?? 0),
      name: (json['BeltName'] ?? json['beltName'] ?? json['Name'] ?? json['name'] ?? '').toString(),
      description: (json['Description'] ?? json['description'] ?? '').toString(),
      price: _toDouble(json['Price'] ?? json['price'] ?? 0),
      imageUrl: (json['ImageUrl'] ?? json['imageUrl'])?.toString(),
      averageRating: _toNullableDouble(json['AverageRating'] ?? json['averageRating']),
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
}

