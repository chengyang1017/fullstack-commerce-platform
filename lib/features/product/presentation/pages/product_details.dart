import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../checkout/presentation/cubit/checkout_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../cart/domain/models/cart_item.dart';
import '../../../checkout/domain/models/checkout_request.dart';
import '../../domain/models/product.dart';
import '../../../address/data/repositories/address_repository.dart';
import '../../../order/data/repositories/order_repository.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetails> createState() {
    return _ProductDetailsState();
  }
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _isFavorite = false;

  Product get product => widget.product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? colorScheme.error : null,
          ),
        ),
        const CartIconButton(),
      ],
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              product.image,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RM ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.soldCount(product.sold),
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return BlocSelector<CartCubit, CartState, int>(
      selector: (state) {
        return state.quantityOf(product.id);
      },
      builder: (context, quantity) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _addToCart,
                    child: Text(
                      quantity == 0
                          ? l10n.addToCart
                          : l10n.addToCartWithQuantity(quantity),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _buyNow,
                    child: Text(l10n.buyNow),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToCart() async {
    try {
      await context.read<CartCubit>().addProduct(product);

      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.productAddedToCart(product.title)),
          action: SnackBarAction(label: l10n.viewCart, onPressed: _openCart),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context);

      final cartState = context.read<CartCubit>().state;

      final message = switch (cartState.errorType) {
        CartErrorType.loadFailed => l10n.cartLoadFailed,

        CartErrorType.updateFailed => l10n.addToCartFailed,

        CartErrorType.clearFailed => l10n.addToCartFailed,

        null => l10n.addToCartFailed,
      };

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _buyNow() async {
    final addressRepository = context.read<AddressRepository>();

    final orderRepository = context.read<OrderRepository>();

    final request = CheckoutRequest.buyNow(
      items: [CartItem(product: product, quantity: 1)],
    );

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return BlocProvider<CheckoutCubit>(
            create: (_) {
              return CheckoutCubit(
                addressRepository: addressRepository,
                orderRepository: orderRepository,
              )..initialize();
            },
            child: CheckoutPage(request: request),
          );
        },
      ),
    );
  }

  void _openCart() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) {
          return const CartPage();
        },
      ),
    );
  }
}
