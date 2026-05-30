import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';

class OrdersApi {
  OrdersApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _ordersPath = '/api/Orders';
  static const String _orderItemsPath = '/api/OrderItems';
  static const String _paymentsPath = '/api/Payments';

  Future<Map<String, dynamic>?> getActiveCart() async {
    final http.Response response = await _apiClient.get('$_ordersPath/Active');
    if (response.statusCode == 204) return null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to get active cart: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final http.Response response = await _apiClient.get('$_ordersPath/My');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
      return jsonList.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createOrder({
    required String orderNumber,
    required DateTime date,
    double price = 0,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'OrderNumber': orderNumber,
      'Date': date.toUtc().toIso8601String(),
      'Price': price,
      'items': <Map<String, dynamic>>[],
    };
    final http.Response response = await _apiClient.post('$_ordersPath/Create', body: json.encode(body));
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
    final http.Response response = await _apiClient.post('$_orderItemsPath/AddToCart', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    final String errorDetail = _parseErrorResponse(response);
    final String message = errorDetail.isNotEmpty ? errorDetail : 'Greška pri dodavanju u korpu (${response.statusCode})';
    throw Exception(message);
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required int orderId,
    String? receiptEmail,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'OrderID': orderId,
      if (receiptEmail != null) 'ReceiptEmail': receiptEmail,
    };
    final http.Response response = await _apiClient.post('$_paymentsPath/create-payment-intent', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    final String detail = _parseErrorResponse(response);
    final String tail = detail.isNotEmpty ? ': $detail' : (response.body.isNotEmpty ? ': ${response.body}' : '');
    throw Exception('PaymentIntent API ${response.statusCode}$tail');
  }

  Future<String> getStripePublishableKey() async {
    final http.Response response = await _apiClient.get('$_paymentsPath/stripe-config');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
      return (data['PublishableKey'] ?? data['publishableKey'] ?? '').toString().trim();
    }
    return '';
  }

  Future<Map<String, dynamic>> confirmPaymentIntent({
    required String paymentIntentId,
    int? orderId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'paymentIntentId': paymentIntentId,
      if (orderId != null) 'orderId': orderId,
    };
    final http.Response response = await _apiClient.post(
      '$_paymentsPath/confirm-payment-intent',
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    final String detail = _parseErrorResponse(response);
    final String tail = detail.isNotEmpty ? ': $detail' : (response.body.isNotEmpty ? ': ${response.body}' : '');
    throw Exception('confirm-payment-intent ${response.statusCode}$tail');
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

  Future<void> cancelActiveCart() async {
    final http.Response response = await _apiClient.delete('$_ordersPath/Active');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to cancel cart: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> confirmMockCheckout() async {
    if (!kDebugMode) {
      throw Exception('Mock checkout is only available in debug mode.');
    }
    final http.Response response = await _apiClient.post('http://localhost:4242/checkout/confirm');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to confirm mock checkout: ${response.statusCode}');
  }
}
