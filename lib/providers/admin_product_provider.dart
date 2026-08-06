import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/admin_product_repository.dart';

enum AdminProductStatus { initial, loading, ready, error }

class AdminProductProvider extends ChangeNotifier {
  AdminProductProvider({required AdminProductRepository repository})
    : _repository = repository;

  final AdminProductRepository _repository;

  AdminProductStatus _status = AdminProductStatus.initial;

  List<Product> _products = const [];

  final Set<String> _busyProductIds = {};

  bool _isCreating = false;
  String? _errorMessage;

  AdminProductStatus get status => _status;

  List<Product> get products {
    return List.unmodifiable(_products);
  }

  List<Product> get activeProducts {
    return _products
        .where((product) => product.isActive)
        .toList(growable: false);
  }

  List<Product> get inactiveProducts {
    return _products
        .where((product) => !product.isActive)
        .toList(growable: false);
  }

  bool get isLoading {
    return _status == AdminProductStatus.loading;
  }

  bool get isCreating => _isCreating;

  String? get errorMessage => _errorMessage;

  bool isProductBusy(String productId) {
    return _busyProductIds.contains(productId);
  }

  Future<void> loadProducts({bool force = false}) async {
    if (_status == AdminProductStatus.loading) {
      return;
    }

    if (!force && _status == AdminProductStatus.ready) {
      return;
    }

    _status = AdminProductStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getProducts();

      _products = List.unmodifiable(result);
      _status = AdminProductStatus.ready;
    } catch (error) {
      _status = AdminProductStatus.error;
      _errorMessage = '加载管理员商品失败：$error';
    }

    notifyListeners();
  }

  Future<void> refreshProducts() {
    return loadProducts(force: true);
  }

  Future<bool> createProduct({
    required String categoryId,
    required String title,
    required String description,
    required String imageUrl,
    required double price,
    required int stock,
  }) async {
    if (_isCreating) {
      return false;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final product = await _repository.createProduct(
        categoryId: categoryId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        price: price,
        stock: stock,
      );

      _products = List.unmodifiable([product, ..._products]);

      return true;
    } catch (error) {
      _errorMessage = '新增商品失败：$error';
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct({
    required String productId,
    String? categoryId,
    String? title,
    String? description,
    String? imageUrl,
    double? price,
    int? stock,
    bool? isActive,
  }) async {
    if (isProductBusy(productId)) {
      return false;
    }

    _setProductBusy(productId, true);
    _errorMessage = null;

    try {
      final updatedProduct = await _repository.updateProduct(
        productId: productId,
        categoryId: categoryId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        price: price,
        stock: stock,
        isActive: isActive,
      );

      _replaceProduct(updatedProduct);

      return true;
    } catch (error) {
      _errorMessage = '修改商品失败：$error';
      return false;
    } finally {
      _setProductBusy(productId, false);
    }
  }

  Future<bool> deactivateProduct(String productId) async {
    if (isProductBusy(productId)) {
      return false;
    }

    _setProductBusy(productId, true);
    _errorMessage = null;

    try {
      await _repository.deactivateProduct(productId);

      final existing = findById(productId);

      if (existing != null) {
        _replaceProduct(existing.copyWith(isActive: false));
      }

      return true;
    } catch (error) {
      _errorMessage = '下架商品失败：$error';
      return false;
    } finally {
      _setProductBusy(productId, false);
    }
  }

  Future<bool> activateProduct(String productId) async {
    if (isProductBusy(productId)) {
      return false;
    }

    _setProductBusy(productId, true);
    _errorMessage = null;

    try {
      final product = await _repository.activateProduct(productId);

      _replaceProduct(product);

      return true;
    } catch (error) {
      _errorMessage = '上架商品失败：$error';
      return false;
    } finally {
      _setProductBusy(productId, false);
    }
  }

  Product? findById(String productId) {
    for (final product in _products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _replaceProduct(Product updatedProduct) {
    final index = _products.indexWhere(
      (product) => product.id == updatedProduct.id,
    );

    if (index == -1) {
      _products = List.unmodifiable([updatedProduct, ..._products]);
      return;
    }

    final nextProducts = List<Product>.from(_products);

    nextProducts[index] = updatedProduct;

    _products = List.unmodifiable(nextProducts);
  }

  void _setProductBusy(String productId, bool isBusy) {
    if (isBusy) {
      _busyProductIds.add(productId);
    } else {
      _busyProductIds.remove(productId);
    }

    notifyListeners();
  }
}
