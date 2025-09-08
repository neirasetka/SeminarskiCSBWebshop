class BagType {
  const BagType({required this.id, required this.name});

  final int id;
  final String name;

  factory BagType.fromJson(Map<String, dynamic> json) {
    return BagType(
      id: _toInt(json['BagTypeID'] ?? json['bagTypeID'] ?? json['ID'] ?? json['id'] ?? 0),
      name: (json['BagName'] ?? json['bagName'] ?? json['Name'] ?? json['name'] ?? '').toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

