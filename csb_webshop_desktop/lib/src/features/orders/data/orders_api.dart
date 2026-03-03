import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class OrdersApi {
  OrdersApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _ordersPath = '/api/Orders';
  static const String _orderItemsPath = '/api/OrderItems';
  static const String _paymentsPath = '/api/Payments';

  Future<Map<String, dynamic>?> getActiveCart({required int userId}) async {
    final http.Response response = await _apiClient.get('$_ordersPath/Active?userId=$userId');
    if (response.statusCode == 204) return null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get active cart: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getOrdersByUser({required int userId}) async {
    final http.Response response = await _apiClient.get('$_ordersPath/ByUser?userId=$userId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
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
    final String errorDetail = _parseErrorResponse(response);
    throw Exception('Failed to create order: ${response.statusCode}${errorDetail.isNotEmpty ? ': $errorDetail' : ''}');
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

  Future<Map<String, dynamic>> createPaymentIntent({
    required int orderId,
    required int amountInCents,
    String currency = 'eur',
    String? receiptEmail,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'OrderID': orderId,
      'AmountInCents': amountInCents,
      'Currency': currency,
      if (receiptEmail != null) 'ReceiptEmail': receiptEmail,
    };
    final http.Response response = await _apiClient.post('$_paymentsPath/create-payment-intent', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create payment intent: ${response.statusCode}');
  }

  Future<void> updatePaymentStatus({required int orderId, required String status}) async {
    final Map<String, dynamic> body = <String, dynamic>{'status': status};
    final http.Response response = await _apiClient.patch('$_ordersPath/$orderId/payment-status', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to update payment status: ${response.statusCode}');
  }

  static String _parseErrorResponse(http.Response response) {
    if (response.body.isEmpty) return '';
    try {
      final Map<String, dynamic>? data = json.decode(response.body) as Map<String, dynamic>?;
      if (data == null) return '';
      final Object? err = data['error'] ?? data['message'] ?? data['title'];
      if (err != null) return err.toString();
      final Object? errors = data['errors'];
      if (errors is Map) {
        final List<String> parts = <String>[];
        for (final MapEntry<dynamic, dynamic> e in errors.entries) {
          final Object? v = e.value;
          final String msg = v is List ? v.join(', ') : v.toString();
          parts.add('${e.key}: $msg');
        }
        return parts.join('; ');
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<void> cancelActiveCart({required int userId}) async {
    final http.Response response = await _apiClient.delete('$_ordersPath/Active?userId=$userId');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to cancel cart: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> confirmMockCheckout() async {
    // Calls the mock node server running on localhost:4242
    final http.Response response = await _apiClient.post('http://localhost:4242/checkout/confirm');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to confirm mock checkout: ${response.statusCode}');
  }
}

