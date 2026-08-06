import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';

enum ProductStatus { initial, loading, ready, error }

class ProductProvider extends ChangeNotifier {
  ProductProvider({required ProductRepository productRepository})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;

  ProductStatus _status = ProductStatus.initial;
  List<Product> _products = const [];
  String? _errorMessage;

  ProductStatus get status => _status;

  List<Product> get products {
    return List.unmodifiable(_products);
  }

  String? get errorMessage => _errorMessage;

  bool get isLoading {
    return _status == ProductStatus.loading;
  }

  Future<void> loadProducts({bool force = false}) async {
    if (_status == ProductStatus.loading) {
      return;
    }

    if (!force && _status == ProductStatus.ready && _products.isNotEmpty) {
      return;
    }

    _status = ProductStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final products = await _productRepository.getProducts();

      _products = List.unmodifiable(products);
      _status = ProductStatus.ready;
    } catch (error) {
      _status = ProductStatus.error;
      _errorMessage = '加载商品失败：$error';
    }

    notifyListeners();
  }

  Future<void> refreshProducts() {
    return loadProducts(force: true);
  }

  Product? findById(String productId) {
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  List<Product> productsByCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty || categoryId == 'all') {
      return products;
    }

    return _products
        .where((product) => product.categoryId == categoryId)
        .toList(growable: false);
  }
}
