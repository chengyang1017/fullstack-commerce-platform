import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../pages/cart_page.dart';

class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) {
        return state.totalQuantity;
      },
      builder: (context, totalQuantity) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: l10n.cart,
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
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      totalQuantity > 99 ? '99+' : '$totalQuantity',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
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
