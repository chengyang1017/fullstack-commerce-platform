import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/product_category.dart';

class CategoryService {
  CategoryService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  Future<List<ProductCategory>>
      getCategories() async {
    final uri =
        Uri.parse('$_baseUrl/api/categories');

    final response = await _client
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load categories: '
        '${response.statusCode}',
      );
    }

    final decoded =
        jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException(
        'Invalid category response',
      );
    }

    return decoded.map((item) {
      return ProductCategory.fromJson(
        Map<String, dynamic>.from(
          item as Map,
        ),
      );
    }).toList(growable: false);
  }

  void dispose() {
    _client.close();
  }
}