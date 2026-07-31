import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../screens/cart_page.dart';

class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, int>(
      selector: (context, cart) {
        return cart.totalQuantity;
      },
      builder: (context, totalQuantity, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: '購物車',
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const CartPage();
                    },
                  ),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
            if (totalQuantity > 0)
              Positioned(
                top: 3,
                right: 2,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      totalQuantity > 99 ? '99+' : '$totalQuantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
