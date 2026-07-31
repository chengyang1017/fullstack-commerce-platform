import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('購物車商品小計計算正確', () {
    const product = Product(
      id: 'product_001',
      categoryId: 'phone',
      title: '測試手機',
      image: 'https://example.com/image.jpg',
      price: 100,
      sold: 0,
    );

    const cartItem = CartItem(
      product: product,
      quantity: 3,
    );

    expect(
      cartItem.subtotal,
      300,
    );
  });
}