import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/customer_user.dart';

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
  static const _accessTokenKey =
      'customer_access_token';
  static const _refreshTokenKey =
      'customer_refresh_token';

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

  String? resolveMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri != null && uri.hasScheme) {
      return trimmed;
    }

    return '$_baseUrl${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }

  Future<CustomerUser?> restoreSession() async {
    final refreshToken =
        await _storage.read(key: _refreshTokenKey);

    if (refreshToken == null || refreshToken.isEmpty) {
      _currentUser = null;
      return null;
    }

    try {
      return await _requestSession(
        path: '/api/auth/customer/refresh',
        body: {
          'refreshToken': refreshToken,
        },
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
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
  }

  Future<CustomerUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _requestSession(
      path: '/api/auth/customer/register',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
  }

  Future<CustomerUser> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final response = await _sendAuthorized(
      (accessToken) async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(
            '$_baseUrl/api/customer/profile/avatar',
          ),
        );

        request.headers['Authorization'] =
            'Bearer $accessToken';
        request.headers['Accept'] = 'application/json';
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            bytes,
            filename: fileName,
          ),
        );

        final streamedResponse =
            await _client.send(request);

        return http.Response.fromStream(
          streamedResponse,
        );
      },
    );

    return _readUserResponse(response);
  }

  Future<CustomerUser> removeAvatar() async {
    final response = await _sendAuthorized(
      (accessToken) {
        return _client.delete(
          Uri.parse(
            '$_baseUrl/api/customer/profile/avatar',
          ),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        );
      },
    );

    return _readUserResponse(response);
  }

  Future<void> logout() async {
    final refreshToken =
        await _storage.read(key: _refreshTokenKey);

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _postJson(
          path: '/api/auth/customer/logout',
          body: {
            'refreshToken': refreshToken,
          },
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to notify server about logout',
        name: 'CustomerAuthService',
        error: error,
        stackTrace: stackTrace,
      );
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
    final responseData = await _postJson(
      path: path,
      body: body,
    );

    final accessToken = responseData['accessToken'];
    final refreshToken = responseData['refreshToken'];
    final userData = responseData['user'];

    if (
      accessToken is! String ||
      accessToken.isEmpty ||
      refreshToken is! String ||
      refreshToken.isEmpty ||
      userData is! Map
    ) {
      throw const CustomerAuthException(
        type: CustomerAuthFailureType.invalidSessionResponse,
      );
    }

    late final CustomerUser user;

    try {
      user = CustomerUser.fromJson(
        Map<String, dynamic>.from(userData),
      );
    } catch (error) {
      throw CustomerAuthException(
        type: CustomerAuthFailureType.invalidSessionResponse,
        cause: error,
      );
    }

    await Future.wait([
      _storage.write(
        key: _accessTokenKey,
        value: accessToken,
      ),
      _storage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      ),
    ]);

    _currentUser = user;
    return user;
  }

  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(String accessToken)
        send,
  ) async {
    var accessToken = await requireAccessToken();
    var response = await _runRequest(
      () => send(accessToken),
    );

    if (response.statusCode != 401) {
      return response;
    }

    final refreshedToken = await refreshAccessToken();

    if (refreshedToken == null || refreshedToken.isEmpty) {
      throw const CustomerAuthException(
        type: CustomerAuthFailureType.sessionExpired,
      );
    }

    accessToken = refreshedToken;
    response = await _runRequest(
      () => send(accessToken),
    );

    return response;
  }

  Future<http.Response> _runRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } catch (error) {
      throw CustomerAuthException(
        type: CustomerAuthFailureType.connectionFailed,
        cause: error,
      );
    }
  }

  CustomerUser _readUserResponse(
    http.Response response,
  ) {
    final responseData = _decodeResponse(response);

    _throwForFailedResponse(
      response,
      responseData,
    );

    final userData = responseData['user'];

    if (userData is! Map) {
      throw const CustomerAuthException(
        type: CustomerAuthFailureType.invalidResponse,
      );
    }

    late final CustomerUser user;

    try {
      user = CustomerUser.fromJson(
        Map<String, dynamic>.from(userData),
      );
    } catch (error) {
      throw CustomerAuthException(
        type: CustomerAuthFailureType.invalidResponse,
        cause: error,
      );
    }

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

    _throwForFailedResponse(
      response,
      responseData,
    );

    return responseData;
  }

  void _throwForFailedResponse(
    http.Response response,
    Map<String, dynamic> responseData,
  ) {
    if (
      response.statusCode >= 200 &&
      response.statusCode < 300
    ) {
      return;
    }

    final rawMessage = responseData['message'];

    throw CustomerAuthException(
      type: response.statusCode == 401
          ? CustomerAuthFailureType.sessionExpired
          : CustomerAuthFailureType.requestFailed,
      statusCode: response.statusCode,
      serverMessage:
          rawMessage is String && rawMessage.isNotEmpty
          ? rawMessage
          : null,
    );
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

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
