class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.orderId,
    this.bagId,
    this.beltId,
    required this.quantity,
    required this.price,
    this.discount,
    this.name,
    this.code,
  });

  final int id;
  final int orderId;
  final int? bagId;
  final int? beltId;
  final int quantity;
  final double price;
  final double? discount;
  final String? name;
  final String? code;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: _toInt(json['OrderItemID'] ?? json['OrderItemsID'] ?? json['id'] ?? 0),
      orderId: _toInt(json['OrderID'] ?? 0),
      bagId: _toNullableInt(json['BagID']),
      beltId: _toNullableInt(json['BeltID']),
      quantity: _toInt(json['Quantity'] ?? 1),
      price: _toDouble(json['Price'] ?? json['price'] ?? 0),
      discount: _toNullableDouble(json['Discount']),
      name: (json['Name'] ?? json['name'])?.toString(),
      code: (json['Code'] ?? json['code'])?.toString(),
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.date,
    required this.userId,
    required this.amount,
    required this.items,
    this.paymentStatus,
    this.shippingStatus,
  });

  final int id;
  final String orderNumber;
  final DateTime date;
  final int userId;
  final double amount;
  final List<OrderItemModel> items;
  final String? paymentStatus;
  final String? shippingStatus;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final List<OrderItemModel> items = <OrderItemModel>[];
    final Object? rawItems = json['OrderItems'] ?? json['orderItems'] ?? json['items'];
    if (rawItems is List) {
      for (final Object e in rawItems) {
        if (e is Map<String, dynamic>) items.add(OrderItemModel.fromJson(e));
      }
    }
    return OrderModel(
      id: _toInt(json['OrderID'] ?? json['orderID'] ?? json['id'] ?? 0),
      orderNumber: (json['OrderNumber'] ?? json['orderNumber'] ?? '').toString(),
      date: DateTime.tryParse((json['Date'] ?? json['date'] ?? '').toString()) ?? DateTime.now(),
      userId: _toInt(json['UserID'] ?? json['userId'] ?? 0),
      amount: _toDouble(json['Amount'] ?? json['Price'] ?? json['amount'] ?? json['price'] ?? 0),
      items: items,
      paymentStatus: (json['PaymentStatus'] ?? json['paymentStatus'])?.toString(),
      shippingStatus: (json['ShippingStatus'] ?? json['shippingStatus'])?.toString(),
    );
  }
}

int _toInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}

int? _toNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '0') ?? 0;
}

double? _toNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

