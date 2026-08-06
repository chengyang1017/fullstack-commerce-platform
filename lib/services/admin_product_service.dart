import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class AdminProductService {
  AdminProductService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// 获取全部商品，包括已下架商品。
  Future<List<Product>> getProducts() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/admin/products'))
        .timeout(const Duration(seconds: 10));

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(decoded, fallback: '获取管理员商品列表失败'));
    }

    if (decoded is! List) {
      throw const FormatException('管理员商品列表格式错误');
    }

    return decoded
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// 新增商品。
  Future<Product> createProduct({
    required String categoryId,
    required String title,
    required String description,
    required String imageUrl,
    required double price,
    required int stock,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/admin/products'),
          headers: _jsonHeaders,
          body: utf8.encode(
            jsonEncode({
              'categoryId': categoryId,
              'title': title,
              'description': description,
              'imageUrl': imageUrl,
              'price': price,
              'stock': stock,
            }),
          ),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw Exception(_readErrorMessage(decoded, fallback: '新增商品失败'));
    }

    return _readProduct(decoded);
  }

  /// 修改商品资料、库存或上下架状态。
  Future<Product> updateProduct({
    required String productId,
    String? categoryId,
    String? title,
    String? description,
    String? imageUrl,
    double? price,
    int? stock,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{
      if (categoryId != null) 'categoryId': categoryId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      if (isActive != null) 'isActive': isActive,
    };

    if (data.isEmpty) {
      throw ArgumentError('至少需要提供一个修改字段');
    }

    final response = await _client
        .patch(
          Uri.parse('$_baseUrl/api/admin/products/$productId'),
          headers: _jsonHeaders,
          body: utf8.encode(jsonEncode(data)),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(decoded, fallback: '修改商品失败'));
    }

    return _readProduct(decoded);
  }

  /// 下架商品，后端不会真正删除数据库记录。
  Future<void> deactivateProduct(String productId) async {
    final response = await _client
        .delete(Uri.parse('$_baseUrl/api/admin/products/$productId'))
        .timeout(const Duration(seconds: 10));

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(_readErrorMessage(decoded, fallback: '下架商品失败'));
    }
  }

  /// 重新上架商品。
  Future<Product> activateProduct(String productId) {
    return updateProduct(productId: productId, isActive: true);
  }

  Object? _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }

    final body = utf8.decode(response.bodyBytes);

    return jsonDecode(body);
  }

  Product _readProduct(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('服务器响应格式错误');
    }

    final productJson = decoded['product'];

    if (productJson is! Map<String, dynamic>) {
      throw const FormatException('服务器没有返回商品数据');
    }

    return Product.fromJson(productJson);
  }

  String _readErrorMessage(Object? decoded, {required String fallback}) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }

  void dispose() {
    _client.close();
  }

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };
}
