import '../models/product.dart';
import '../services/admin_product_service.dart';

abstract class AdminProductRepository {
  Future<List<Product>> getProducts();

  Future<Product> createProduct({
    required String categoryId,
    required String title,
    required String description,
    required String imageUrl,
    required double price,
    required int stock,
  });

  Future<Product> updateProduct({
    required String productId,
    String? categoryId,
    String? title,
    String? description,
    String? imageUrl,
    double? price,
    int? stock,
    bool? isActive,
  });

  Future<void> deactivateProduct(String productId);

  Future<Product> activateProduct(String productId);
}

class ApiAdminProductRepository implements AdminProductRepository {
  ApiAdminProductRepository({AdminProductService? service})
    : _service = service ?? AdminProductService();

  final AdminProductService _service;

  @override
  Future<List<Product>> getProducts() {
    return _service.getProducts();
  }

  @override
  Future<Product> createProduct({
    required String categoryId,
    required String title,
    required String description,
    required String imageUrl,
    required double price,
    required int stock,
  }) {
    return _service.createProduct(
      categoryId: categoryId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      price: price,
      stock: stock,
    );
  }

  @override
  Future<Product> updateProduct({
    required String productId,
    String? categoryId,
    String? title,
    String? description,
    String? imageUrl,
    double? price,
    int? stock,
    bool? isActive,
  }) {
    return _service.updateProduct(
      productId: productId,
      categoryId: categoryId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      price: price,
      stock: stock,
      isActive: isActive,
    );
  }

  @override
  Future<void> deactivateProduct(String productId) {
    return _service.deactivateProduct(productId);
  }

  @override
  Future<Product> activateProduct(String productId) {
    return _service.activateProduct(productId);
  }

  void dispose() {
    _service.dispose();
  }
}
