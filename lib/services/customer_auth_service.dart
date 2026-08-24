import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/customer_user.dart';

enum CustomerAuthFailureType {
  sessionExpired,
  connectionFailed,
  invalidSessionResponse,
  invalidResponse,
  requestFailed,
}

class CustomerAuthException implements Exception {
  const CustomerAuthException({
    required this.type,
    this.statusCode,
    this.serverMessage,
    this.cause,
  });

  final CustomerAuthFailureType type;

  final int? statusCode;

  /// 服务器返回的原始错误说明。
  ///
  /// 保留给日志 / 调试使用，
  /// 不应该直接显示给最终用户。
  final String? serverMessage;

  final Object? cause;

  @override
  String toString() {
    return 'CustomerAuthException('
        'type: $type, '
        'statusCode: $statusCode, '
        'serverMessage: $serverMessage, '
        'cause: $cause'
        ')';
  }
}

class CustomerAuthService {
  static const _accessTokenKey = 'customer_access_token';

  static const _refreshTokenKey = 'customer_refresh_token';

  CustomerAuthService({
    http.Client? client,
    FlutterSecureStorage? storage,
    String baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final http.Client _client;

  final FlutterSecureStorage _storage;

  final String _baseUrl;

  CustomerUser? _currentUser;

  CustomerUser? get currentUser => _currentUser;

  String get baseUrl => _baseUrl;

  Future<CustomerUser?> restoreSession() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      _currentUser = null;

      return null;
    }

    try {
      return await _requestSession(
        path: '/api/auth/customer/refresh',
        body: {'refreshToken': refreshToken},
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to restore customer session',
        name: 'CustomerAuthService',
        error: error,
        stackTrace: stackTrace,
      );

      await clearLocalSession();

      return null;
    }
  }

  Future<CustomerUser> login({
    required String email,
    required String password,
  }) {
    return _requestSession(
      path: '/api/auth/customer/login',
      body: {'email': email.trim(), 'password': password},
    );
  }

  Future<CustomerUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _requestSession(
      path: '/api/auth/customer/register',
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _postJson(
          path: '/api/auth/customer/logout',
          body: {'refreshToken': refreshToken},
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to notify server about logout',
        name: 'CustomerAuthService',
        error: error,
        stackTrace: stackTrace,
      );

      // 即使服务器暂时不可访问，
      // 本机也必须完成退出。
    } finally {
      await clearLocalSession();
    }
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String> requireAccessToken() async {
    var accessToken = await readAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      return accessToken;
    }

    final restoredUser = await restoreSession();

    if (restoredUser == null) {
      throw const CustomerAuthException(
        type: CustomerAuthFailureType.sessionExpired,
      );
    }

    accessToken = await readAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const CustomerAuthException(
        type: CustomerAuthFailureType.sessionExpired,
      );
    }

    return accessToken;
  }

  Future<String?> refreshAccessToken() async {
    final restoredUser = await restoreSession();

    if (restoredUser == null) {
      return null;
    }

    return readAccessToken();
  }

  Future<void> clearLocalSession() async {
    _currentUser = null;

    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<CustomerUser> _requestSession({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    final responseData = await _postJson(path: path, body: body);

    final accessToken = responseData['accessToken'];

    final refreshToken = responseData['refreshToken'];

    final userData = responseData['user'];

    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty ||
        userData is! Map) {
      throw const CustomerAuthException(
        type: CustomerAuthFailureType.invalidSessionResponse,
      );
    }

    late final CustomerUser user;

    try {
      user = CustomerUser.fromJson(Map<String, dynamic>.from(userData));
    } catch (error) {
      throw CustomerAuthException(
        type: CustomerAuthFailureType.invalidSessionResponse,
        cause: error,
      );
    }

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);

    _currentUser = user;

    return user;
  }

  Future<Map<String, dynamic>> _postJson({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    late final http.Response response;

    try {
      response = await _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
    } catch (error) {
      throw CustomerAuthException(
        type: CustomerAuthFailureType.connectionFailed,
        cause: error,
      );
    }

    final responseData = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final rawMessage = responseData['message'];

      throw CustomerAuthException(
        type: CustomerAuthFailureType.requestFailed,
        statusCode: response.statusCode,
        serverMessage: rawMessage is String && rawMessage.isNotEmpty
            ? rawMessage
            : null,
      );
    }

    return responseData;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (error) {
      throw CustomerAuthException(
        type: CustomerAuthFailureType.invalidResponse,
        cause: error,
      );
    }

    throw const CustomerAuthException(
      type: CustomerAuthFailureType.invalidResponse,
    );
  }

  void dispose() {
    _client.close();
  }
}
