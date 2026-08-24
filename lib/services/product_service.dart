import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

enum ProductServiceErrorType {
  requestFailed,
  unexpectedStatusCode,
  invalidResponse,
}

class ProductServiceException implements Exception {
  const ProductServiceException({
    required this.type,
    this.statusCode,
    this.cause,
  });

  final ProductServiceErrorType type;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    return 'ProductServiceException('
        'type: $type, '
        'statusCode: $statusCode, '
        'cause: $cause'
        ')';
  }
}

class ProductService {
  ProductService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  Future<List<Product>> getProducts() async {
    final uri = Uri.parse('$_baseUrl/api/products');

    late final http.Response response;

    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 10));
    } catch (error) {
      throw ProductServiceException(
        type: ProductServiceErrorType.requestFailed,
        cause: error,
      );
    }

    if (response.statusCode != 200) {
      throw ProductServiceException(
        type: ProductServiceErrorType.unexpectedStatusCode,
        statusCode: response.statusCode,
      );
    }

    try {
      final Object? decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw const ProductServiceException(
          type: ProductServiceErrorType.invalidResponse,
        );
      }

      return decoded
          .map((item) {
            if (item is! Map) {
              throw const ProductServiceException(
                type: ProductServiceErrorType.invalidResponse,
              );
            }

            return Product.fromJson(Map<String, dynamic>.from(item));
          })
          .toList(growable: false);
    } on ProductServiceException {
      rethrow;
    } catch (error) {
      throw ProductServiceException(
        type: ProductServiceErrorType.invalidResponse,
        cause: error,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
