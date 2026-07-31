import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartRepository {
  final CartService _service;

  const CartRepository({required CartService service}) : _service = service;

  Future<List<CartItem>> loadCart() {
    return _service.loadItems();
  }

  Future<void> saveCart(List<CartItem> items) {
    return _service.saveItems(items);
  }

  Future<void> clearCart() {
    return _service.clear();
  }
}
