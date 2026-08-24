import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order.dart';
import 'customer_auth_service.dart';

enum ApiOrderFailureType {
  invalidOrderListResponse,
  invalidOrderResponse,
  invalidOrderId,
  connectionFailed,
  authenticationExpired,
  requestFailed,
  invalidResponse,
}

class ApiOrderException implements Exception {
  const ApiOrderException({
    required this.type,
    this.statusCode,
    this.serverMessage,
    this.cause,
  });

  final ApiOrderFailureType type;

  final int? statusCode;

  /// Backend message retained for diagnostics only.
  /// Do not display this directly in the UI.
  final String? serverMessage;

  final Object? cause;

  @override
  String toString() {
    return 'ApiOrderException('
        'type: $type, '
        'statusCode: $statusCode, '
        'serverMessage: $serverMessage, '
        'cause: $cause'
        ')';
  }
}

abstract class OrderService {
  Future<List<Order>> loadOrders();

  Future<Order> createOrder(Order order);

  Future<Order> cancelOrder(String orderId);

  void dispose();
}

class ApiOrderService implements OrderService {
  ApiOrderService({
    required CustomerAuthService authService,
    http.Client? client,
  }) : _authService = authService,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final CustomerAuthService _authService;
  final http.Client _client;
  final bool _ownsClient;

  Uri get _ordersUri {
    return Uri.parse('${_authService.baseUrl}/api/customer/orders');
  }

  @override
  Future<List<Order>> loadOrders() async {
    final response = await _sendAuthorized(method: 'GET', uri: _ordersUri);

    final decoded = _decodeResponse(response);

    if (decoded is! List) {
      throw const ApiOrderException(
        type: ApiOrderFailureType.invalidOrderListResponse,
      );
    }

    try {
      return decoded
          .map((item) => Order.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false);
    } catch (error) {
      throw ApiOrderException(
        type: ApiOrderFailureType.invalidOrderListResponse,
        cause: error,
      );
    }
  }

  @override
  Future<Order> createOrder(Order order) async {
    final response = await _sendAuthorized(
      method: 'POST',
      uri: _ordersUri,
      body: order.toCreateOrderJson(),
    );

    return _readOrderResponse(response);
  }

  @override
  Future<Order> cancelOrder(String orderId) async {
    final normalizedOrderId = orderId.trim();

    if (normalizedOrderId.isEmpty) {
      throw const ApiOrderException(type: ApiOrderFailureType.invalidOrderId);
    }

    final uri = Uri.parse(
      '${_ordersUri.toString()}/'
      '${Uri.encodeComponent(normalizedOrderId)}/cancel',
    );

    final response = await _sendAuthorized(method: 'POST', uri: uri);

    return _readOrderResponse(response);
  }

  Order _readOrderResponse(http.Response response) {
    final decoded = _decodeResponse(response);

    if (decoded is! Map) {
      throw ApiOrderException(
        type: ApiOrderFailureType.invalidOrderResponse,
        statusCode: response.statusCode,
      );
    }

    try {
      return Order.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      throw ApiOrderException(
        type: ApiOrderFailureType.invalidOrderResponse,
        statusCode: response.statusCode,
        cause: error,
      );
    }
  }

  Future<http.Response> _sendAuthorized({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    bool allowRefresh = true,
  }) async {
    late final String accessToken;

    try {
      accessToken = await _authService.requireAccessToken();
    } on CustomerAuthException catch (error) {
      throw ApiOrderException(
        type: ApiOrderFailureType.authenticationExpired,
        cause: error,
      );
    }

    late final http.Response response;

    try {
      response = await _send(
        method: method,
        uri: uri,
        accessToken: accessToken,
        body: body,
      );
    } catch (error) {
      throw ApiOrderException(
        type: ApiOrderFailureType.connectionFailed,
        cause: error,
      );
    }

    if (response.statusCode == 401) {
      if (!allowRefresh) {
        throw ApiOrderException(
          type: ApiOrderFailureType.authenticationExpired,
          statusCode: response.statusCode,
        );
      }

      String? refreshedToken;

      try {
        refreshedToken = await _authService.refreshAccessToken();
      } catch (error) {
        throw ApiOrderException(
          type: ApiOrderFailureType.authenticationExpired,
          statusCode: response.statusCode,
          cause: error,
        );
      }

      if (refreshedToken == null || refreshedToken.isEmpty) {
        throw ApiOrderException(
          type: ApiOrderFailureType.authenticationExpired,
          statusCode: response.statusCode,
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

      final rawMessage = decoded is Map ? decoded['message'] : null;

      throw ApiOrderException(
        type: ApiOrderFailureType.requestFailed,
        statusCode: response.statusCode,
        serverMessage: rawMessage is String && rawMessage.isNotEmpty
            ? rawMessage
            : null,
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
        return _client.get(uri, headers: headers);

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
          'Unsupported request method',
        );
    }
  }

  Object? _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (error) {
      throw ApiOrderException(
        type: ApiOrderFailureType.invalidResponse,
        statusCode: response.statusCode,
        cause: error,
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
