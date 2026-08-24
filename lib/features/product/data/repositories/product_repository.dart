import '../../domain/models/product.dart';
import '../services/product_service.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
}

class ApiProductRepository implements ProductRepository {
  ApiProductRepository({ProductService? productService})
    : _productService = productService ?? ProductService();

  final ProductService _productService;

  @override
  Future<List<Product>> getProducts() {
    return _productService.getProducts();
  }

  void dispose() {
    _productService.dispose();
  }
}
