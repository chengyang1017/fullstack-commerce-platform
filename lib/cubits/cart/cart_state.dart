import '../../models/cart_item.dart';

enum CartStatus { initial, loading, ready, error }

enum CartErrorType { loadFailed, clearFailed, updateFailed }

class CartState {
  const CartState({
    this.status = CartStatus.initial,
    this.items = const [],
    this.errorType,
  });

  final CartStatus status;
  final List<CartItem> items;
  final CartErrorType? errorType;

  bool get isLoading {
    return status == CartStatus.loading;
  }

  bool get isEmpty {
    return items.isEmpty;
  }

  int get productTypeCount {
    return items.length;
  }

  int get totalQuantity {
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }

  double get totalPrice {
    return items.fold<double>(0, (total, item) => total + item.subtotal);
  }

  int quantityOf(String productId) {
    for (final item in items) {
      if (item.product.id == productId) {
        return item.quantity;
      }
    }

    return 0;
  }

  bool containsProduct(String productId) {
    return items.any((item) => item.product.id == productId);
  }
}
