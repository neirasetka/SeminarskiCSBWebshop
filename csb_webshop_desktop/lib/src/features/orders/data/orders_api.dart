import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/paged_result.dart';
import '../../../core/api_client.dart';
import '../../../core/api_exception.dart';

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
    final String errorDetail = _parseErrorResponse(response);
    final String extra = errorDetail.isNotEmpty ? ': $errorDetail' : _rawBodySnippet(response);
    throw ApiException(
      statusCode: response.statusCode,
      message: 'GET /Orders/Active nije uspio$extra',
      rawBody: response.body.isNotEmpty ? response.body : null,
    );
  }

  Future<PagedResult<Map<String, dynamic>>> getMyOrders({int page = 1, int pageSize = 20}) async {
    final http.Response response = await _apiClient.get(
      '$_ordersPath/My?Page=$page&PageSize=$pageSize',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return PagedResult.fromJson(map, (Map<String, dynamic> item) => item);
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createOrder({
    required String orderNumber,
    required DateTime date,
    double? price,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'OrderNumber': orderNumber,
      'Date': date.toUtc().toIso8601String(),
      if (price != null) 'Price': price,
      'items': <Map<String, dynamic>>[],
    };
    final http.Response response = await _apiClient.post('$_ordersPath/Create', body: json.encode(body));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    final String errorDetail = _parseErrorResponse(response);
    final String extra = errorDetail.isNotEmpty ? ': $errorDetail' : _rawBodySnippet(response);
    throw ApiException(
      statusCode: response.statusCode,
      message: 'POST /Orders/Create nije uspio$extra',
      rawBody: response.body.isNotEmpty ? response.body : null,
    );
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
    final String base = errorDetail.isNotEmpty
        ? errorDetail
        : 'Greška pri dodavanju u korpu${_emptyBodyHint(response)}';
    final String ids =
        ' [AddToCart orderId=$orderId bagId=${bagId ?? '—'} beltId=${beltId ?? '—'} qty=$quantity price=$price]';
    throw ApiException(
      statusCode: response.statusCode,
      message: '$base$ids',
      rawBody: response.body.isNotEmpty ? response.body : null,
    );
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
    throw Exception('Failed to create payment intent: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createCheckoutSession({
    required int orderId,
    String? receiptEmail,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'OrderID': orderId,
      if (receiptEmail != null) 'ReceiptEmail': receiptEmail,
    };
    final http.Response response = await _apiClient.post(
      '$_paymentsPath/create-checkout-session',
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create checkout session: ${response.statusCode}');
  }

  Future<Map<String, dynamic>?> getOrder({required int orderId}) async {
    final http.Response response = await _apiClient.get('$_ordersPath/$orderId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 404) return null;
    throw Exception('Failed to get order: ${response.statusCode}');
  }

  /// Sve narudžbe (samo admin token).
  Future<List<Map<String, dynamic>>> listAllOrders({String? orderNumberPrefix}) async {
    const int pageSize = 100;
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final PagedResult<Map<String, dynamic>> result = await listOrdersPage(
        orderNumberPrefix: orderNumberPrefix,
        page: page,
        pageSize: pageSize,
      );
      all.addAll(result.items);
      if (!result.hasMore) break;
      page++;
    }
    return all;
  }

  Future<PagedResult<Map<String, dynamic>>> listOrdersPage({
    String? orderNumberPrefix,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, String> params = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      if (orderNumberPrefix != null && orderNumberPrefix.trim().isNotEmpty)
        'OrderNumber': orderNumberPrefix.trim(),
    };
    final http.Response response = await _apiClient.get('$_ordersPath?${Uri(queryParameters: params).query}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> map = json.decode(response.body) as Map<String, dynamic>;
      return PagedResult.fromJson(map, (Map<String, dynamic> item) => item);
    }
    final String errorDetail = _parseErrorResponse(response);
    final String extra = errorDetail.isNotEmpty ? ': $errorDetail' : _rawBodySnippet(response);
    throw ApiException(
      statusCode: response.statusCode,
      message: 'GET /Orders (admin) nije uspio$extra',
      rawBody: response.body.isNotEmpty ? response.body : null,
    );
  }

  /// Postavlja status isporuke (npr. Shipped). Samo admin na API-ju.
  Future<void> updateShippingStatus({
    required int orderId,
    required String status,
    String? message,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'status': status,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    };
    final http.Response response = await _apiClient.patch(
      '/api/orders/$orderId/shipping/status',
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final String errorDetail = _parseErrorResponse(response);
    final String extra = errorDetail.isNotEmpty ? ': $errorDetail' : _rawBodySnippet(response);
    throw ApiException(
      statusCode: response.statusCode,
      message: 'PATCH shipping/status (orderId=$orderId) nije uspio$extra',
      rawBody: response.body.isNotEmpty ? response.body : null,
    );
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
    throw Exception('Failed to confirm payment intent: ${response.statusCode}');
  }

  static String _parseErrorResponse(http.Response response) {
    if (response.body.isEmpty) return '';
    try {
      final Map<String, dynamic>? data = json.decode(response.body) as Map<String, dynamic>?;
      if (data == null) return '';
      // error, message, title, detail (ProblemDetails)
      final Object? err = data['error'] ?? data['message'] ?? data['title'] ?? data['detail'];
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

  static String _rawBodySnippet(http.Response response) {
    if (response.body.isEmpty) return '';
    final String b = response.body.length > 400 ? '${response.body.substring(0, 400)}…' : response.body;
    return ' | tijelo: $b';
  }

  static String _emptyBodyHint(http.Response response) {
    if (response.body.isNotEmpty) return '';
    return ' (prazan odgovor, HTTP ${response.statusCode})';
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

  Future<Map<String, dynamic>> confirmCheckoutSession({
    required String sessionId,
    int? orderId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'sessionId': sessionId,
      if (orderId != null) 'orderId': orderId,
    };
    final http.Response response = await _apiClient.post(
      '$_paymentsPath/confirm-checkout-session',
      body: json.encode(body),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to confirm checkout session: ${response.statusCode}');
  }
}

