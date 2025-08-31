import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class OrdersApi {
  OrdersApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _ordersPath = '/api/Orders';
  static const String _orderItemsPath = '/api/OrderItems';

  Future<Map<String, dynamic>?> getActiveCart({required int userId}) async {
    final http.Response response = await _apiClient.get('$_ordersPath/Active?userId=$userId');
    if (response.statusCode == 204) return null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get active cart: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createOrder({
    required int userId,
    required String orderNumber,
    required DateTime date,
    double price = 0,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'OrderNumber': orderNumber,
      'Date': date.toUtc().toIso8601String(),
      'Price': price,
      'UserID': userId,
      'items': <Map<String, dynamic>>[],
    };
    final http.Response response = await _apiClient.post(_ordersPath + '/Create', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create order: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addItem({
    required int orderId,
    int? bagId,
    int? beltId,
    required int quantity,
    required double price,
    double? discount,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      if (bagId != null) 'BagID': bagId,
      if (beltId != null) 'BeltID': beltId,
      'OrderID': orderId,
      'Quantity': quantity,
      'Price': price,
      if (discount != null) 'Discount': discount,
    };
    final http.Response response = await _apiClient.post(_orderItemsPath, body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to add item: ${response.statusCode}');
  }
}

