import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/customer_user.dart';

class CustomerAuthException implements Exception {
  final String message;

  const CustomerAuthException(this.message);

  @override
  String toString() => message;
}

class CustomerAuthService {
  static const _accessTokenKey = 'customer_access_token';

  static const _refreshTokenKey = 'customer_refresh_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  CustomerUser? _currentUser;

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
    } catch (_) {
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
    } catch (_) {
      // 即使服务器暂时无法访问，本机也必须完成退出。
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
      throw const CustomerAuthException('登入已失效，請重新登入');
    }

    accessToken = await readAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw const CustomerAuthException('登入已失效，請重新登入');
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
      throw const CustomerAuthException('服务器返回的登录资料无效');
    }

    final user = CustomerUser.fromJson(Map<String, dynamic>.from(userData));

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
    http.Response response;

    try {
      response = await _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: const {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const CustomerAuthException('无法连接服务器，请检查网络和后端服务');
    }

    final responseData = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = responseData['message'];

      throw CustomerAuthException(
        message is String && message.isNotEmpty ? message : '请求失败，请稍后重试',
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
    } catch (_) {
      throw const CustomerAuthException('服务器返回格式无效');
    }

    throw const CustomerAuthException('服务器返回格式无效');
  }

  void dispose() {
    _client.close();
  }
}
