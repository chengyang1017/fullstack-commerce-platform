import '../../domain/models/product_category.dart';
import '../services/category_service.dart';

class CategoryRepository {
  CategoryRepository({
    CategoryService? service,
  }) : _service = service ?? CategoryService();

  final CategoryService _service;

  Future<List<ProductCategory>> getCategories() {
    return _service.getCategories();
  }

  void dispose() {
    _service.dispose();
  }
}