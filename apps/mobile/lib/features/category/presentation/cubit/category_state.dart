import '../../domain/models/product_category.dart';

enum CategoryErrorType {
  loadFailed,
}

sealed class CategoryState {
  const CategoryState();
}

final class CategoryInitial
    extends CategoryState {
  const CategoryInitial();
}

final class CategoryLoading
    extends CategoryState {
  const CategoryLoading();
}

final class CategoryReady
    extends CategoryState {
  const CategoryReady({
    required this.categories,
  });

  final List<ProductCategory> categories;
}

final class CategoryError
    extends CategoryState {
  const CategoryError({
    required this.type,
  });

  final CategoryErrorType type;
}