import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/cart/cart_cubit.dart';
import '../cubits/cart/cart_state.dart';
import '../screens/cart_page.dart';

class CartIconButton extends StatelessWidget {
  const CartIconButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CartCubit,
      CartState,
      int
    >(
      selector: (state) {
        return state.totalQuantity;
      },
      builder: (
        context,
        totalQuantity,
      ) {
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
              icon: const Icon(
                Icons.shopping_cart_outlined,
              ),
            ),

            if (totalQuantity > 0)
              Positioned(
                top: 3,
                right: 2,
                child: IgnorePointer(
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    decoration:
                        const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      totalQuantity > 99
                          ? '99+'
                          : '$totalQuantity',
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
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