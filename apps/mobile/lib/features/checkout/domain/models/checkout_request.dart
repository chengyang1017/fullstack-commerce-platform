import '../../../cart/domain/models/cart_item.dart';

enum CheckoutSource {
  cart,
  buyNow,
}

class CheckoutRequest {
  final CheckoutSource source;
  final List<CartItem> items;

  CheckoutRequest._({
    required this.source,
    required List<CartItem> items,
  }) : items = List<CartItem>.unmodifiable(items);

  factory CheckoutRequest.cart({
    required List<CartItem> items,
  }) {
    return CheckoutRequest._(
      source: CheckoutSource.cart,
      items: items,
    );
  }

  factory CheckoutRequest.buyNow({
    required List<CartItem> items,
  }) {
    return CheckoutRequest._(
      source: CheckoutSource.buyNow,
      items: items,
    );
  }

  bool get isFromCart {
    return source == CheckoutSource.cart;
  }

  bool get isBuyNow {
    return source == CheckoutSource.buyNow;
  }
}
