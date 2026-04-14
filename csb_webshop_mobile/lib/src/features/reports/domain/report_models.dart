/// Daily revenue point from [GET /api/Reports/RevenueByDay].
class RevenueByDayPoint {
  const RevenueByDayPoint({required this.dayUtc, required this.revenue, required this.numPurchases});

  final DateTime dayUtc;
  final double revenue;
  final int numPurchases;

  factory RevenueByDayPoint.fromJson(Map<String, dynamic> json) {
    final Object? rawDay = json['DayUtc'] ?? json['dayUtc'];
    final DateTime? dayUtc = rawDay == null ? null : DateTime.tryParse(rawDay.toString())?.toUtc();
    if (dayUtc == null) {
      throw FormatException('Invalid or missing DayUtc');
    }
    return RevenueByDayPoint(
      dayUtc: dayUtc,
      revenue: _toDouble(json['Revenue'] ?? json['revenue'] ?? 0),
      numPurchases: _toInt(json['NumPurchases'] ?? json['numPurchases'] ?? 0),
    );
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

/// Entry for top-selling bags report (name + quantity).
class TopSellingBagEntry {
  const TopSellingBagEntry({required this.bagName, required this.quantitySold});

  final String bagName;
  final int quantitySold;

  factory TopSellingBagEntry.fromJson(Map<String, dynamic> json) {
    return TopSellingBagEntry(
      bagName: (json['BagName'] ?? json['bagName'] ?? '').toString(),
      quantitySold: _toInt(json['QuantitySold'] ?? json['quantitySold'] ?? 0),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

/// Entry for order status counts report (status name + count).
class OrderStatusCountEntry {
  const OrderStatusCountEntry({required this.statusName, required this.count});

  final String statusName;
  final int count;

  factory OrderStatusCountEntry.fromJson(Map<String, dynamic> json) {
    return OrderStatusCountEntry(
      statusName: (json['StatusName'] ?? json['statusName'] ?? '').toString(),
      count: _toInt(json['Count'] ?? json['count'] ?? 0),
    );
  }

  static int _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
