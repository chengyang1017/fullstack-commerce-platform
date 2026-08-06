import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import 'customer_auth_service.dart';

class ApiOrderException implements Exception {
  final String message;
  final int? statusCode;

  const ApiOrderException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() => message;
}

abstract class OrderService {
  Future<List<Order>> loadOrders();

  Future<Order> createOrder(Order order);

  Future<Order> cancelOrder(String orderId);

  void dispose();
}

class ApiOrderService implements OrderService {
  final CustomerAuthService _authService;
  final http.Client _client;
  final bool _ownsClient;

  ApiOrderService({
    required CustomerAuthService authService,
    http.Client? client,
  }) : _authService = authService,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  Uri get _ordersUri {
    return Uri.parse(
      '${_authService.baseUrl}/api/customer/orders',
    );
  }

  @override
  Future<List<Order>> loadOrders() async {
    final response = await _sendAuthorized(
      method: 'GET',
      uri: _ordersUri,
    );

    final decoded = _decodeResponse(response);

    if (decoded is! List) {
      throw const ApiOrderException('服务器返回的订单列表格式无效');
    }

    try {
      return decoded
          .map(
            (item) => Order.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      throw const ApiOrderException('服务器返回的订单资料格式无效');
    }
  }

  @override
  Future<Order> createOrder(Order order) async {
    final response = await _sendAuthorized(
      method: 'POST',
      uri: _ordersUri,
      body: order.toCreateOrderJson(),
    );

    return _readOrderResponse(
      response,
      invalidMessage: '服务器返回的新订单资料格式无效',
    );
  }

  @override
  Future<Order> cancelOrder(String orderId) async {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      throw const ApiOrderException('订单 ID 不能为空');
    }

    final uri = Uri.parse(
      '${_ordersUri.toString()}/'
      '${Uri.encodeComponent(normalizedOrderId)}/cancel',
    );

    final response = await _sendAuthorized(
      method: 'POST',
      uri: uri,
    );

    return _readOrderResponse(
      response,
      invalidMessage: '服务器返回的取消订单资料格式无效',
    );
  }

  Order _readOrderResponse(
    http.Response response, {
    required String invalidMessage,
  }) {
    final decoded = _decodeResponse(response);

    if (decoded is! Map) {
      throw ApiOrderException(invalidMessage);
    }

    try {
      return Order.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      throw ApiOrderException(invalidMessage);
    }
  }

  Future<http.Response> _sendAuthorized({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    bool allowRefresh = true,
  }) async {
    final accessToken = await _authService.requireAccessToken();

    http.Response response;

    try {
      response = await _send(
        method: method,
        uri: uri,
        accessToken: accessToken,
        body: body,
      );
    } catch (_) {
      throw const ApiOrderException('无法连接服务器，请检查网络和后端服务');
    }

    if (response.statusCode == 401 && allowRefresh) {
      final refreshedToken = await _authService.refreshAccessToken();

      if (refreshedToken == null || refreshedToken.isEmpty) {
        throw const ApiOrderException(
          '登入已失效，請重新登入',
          statusCode: 401,
        );
      }

      return _sendAuthorized(
        method: method,
        uri: uri,
        body: body,
        allowRefresh: false,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = _decodeResponse(response);

      final message = decoded is Map ? decoded['message'] : null;

      throw ApiOrderException(
        message is String && message.isNotEmpty
            ? message
            : '订单请求失败，请稍后重试',
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Future<http.Response> _send({
    required String method,
    required Uri uri,
    required String accessToken,
    Map<String, dynamic>? body,
  }) {
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
      if (body != null) 'Content-Type': 'application/json; charset=utf-8',
    };

    switch (method) {
      case 'GET':
        return _client.get(
          uri,
          headers: headers,
        );

      case 'POST':
        return _client.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );

      default:
        throw ArgumentError.value(
          method,
          'method',
          '不支持的请求方法',
        );
    }
  }

  Object? _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(
        utf8.decode(response.bodyBytes),
      );
    } catch (_) {
      throw ApiOrderException(
        '服务器返回格式无效',
        statusCode: response.statusCode,
      );
    }
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}
