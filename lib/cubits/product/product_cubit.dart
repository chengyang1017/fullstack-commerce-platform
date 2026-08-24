import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(const ProductInitial());

  final ProductRepository _productRepository;

  Future<void> loadProducts({bool force = false}) async {
    if (state is ProductLoading) {
      return;
    }

    final currentState = state;

    if (!force &&
        currentState is ProductReady &&
        currentState.products.isNotEmpty) {
      return;
    }

    emit(const ProductLoading());

    try {
      final products = await _productRepository.getProducts();

      emit(ProductReady(products: List.unmodifiable(products)));
    } catch (error) {
      emit(ProductError(message: '加载商品失败：$error'));
    }
  }

  Future<void> refreshProducts() {
    return loadProducts(force: true);
  }

  Product? findById(String productId) {
    final currentState = state;

    if (currentState is! ProductReady) {
      return null;
    }

    for (final product in currentState.products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  List<Product> productsByCategory(String? categoryId) {
    final currentState = state;

    if (currentState is! ProductReady) {
      return const [];
    }

    if (categoryId == null || categoryId.isEmpty || categoryId == 'all') {
      return currentState.products;
    }

    return currentState.products
        .where((product) => product.categoryId == categoryId)
        .toList(growable: false);
  }
}
