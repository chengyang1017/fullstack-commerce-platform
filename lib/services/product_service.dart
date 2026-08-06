import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  Future<List<Product>> getProducts() async {
    final uri = Uri.parse('$_baseUrl/api/products');

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('获取商品失败，状态码：${response.statusCode}');
    }

    final Object? decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception('商品数据格式错误');
    }

    return decoded
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _client.close();
  }
}
