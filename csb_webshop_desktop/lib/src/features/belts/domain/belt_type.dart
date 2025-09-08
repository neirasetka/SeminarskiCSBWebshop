class BeltType {
  const BeltType({required this.id, required this.name});

  final int id;
  final String name;

  factory BeltType.fromJson(Map<String, dynamic> json) {
    return BeltType(
      id: _toInt(json['BeltTypeID'] ?? json['beltTypeID'] ?? json['ID'] ?? json['id'] ?? 0),
      name: (json['BeltName'] ?? json['beltName'] ?? json['Name'] ?? json['name'] ?? '').toString(),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

