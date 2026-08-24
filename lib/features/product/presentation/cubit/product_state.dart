import '../../domain/models/product.dart';

enum ProductErrorType { loadFailed }

sealed class ProductState {
  const ProductState();
}

final class ProductInitial extends ProductState {
  const ProductInitial();
}

final class ProductLoading extends ProductState {
  const ProductLoading();
}

final class ProductReady extends ProductState {
  const ProductReady({required this.products});

  final List<Product> products;
}

final class ProductError extends ProductState {
  const ProductError({required this.type});

  final ProductErrorType type;
}
