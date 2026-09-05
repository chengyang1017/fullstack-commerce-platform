import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../../../checkout/presentation/cubit/checkout_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../checkout/domain/models/checkout_request.dart';
import '../../../address/data/repositories/address_repository.dart';
import '../../../order/data/repositories/order_repository.dart';
import '../widgets/cart_item_tile.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() {
    return _CartPageState();
  }
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.cartTitle(state.totalQuantity)),
            actions: [
              if (!state.isEmpty)
                TextButton(
                  onPressed: _confirmClearCart,
                  child: Text(l10n.clear),
                ),
            ],
          ),
          body: _buildBody(state),
          bottomNavigationBar: state.isEmpty ? null : _buildCheckoutBar(state),
        );
      },
    );
  }

  Widget _buildBody(CartState state) {
    if (state.isLoading && state.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CartStatus.error && state.isEmpty) {
      return _buildErrorView(state);
    }

    if (state.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () {
        return context.read<CartCubit>().loadCart(force: true);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: state.items.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          final item = state.items[index];

          return CartItemTile(
            key: ValueKey(item.product.id),
            item: item,
            onIncrease: () {
              _runCartAction(() {
                return context.read<CartCubit>().increaseQuantity(
                  item.product.id,
                );
              });
            },
            onDecrease: () {
              _runCartAction(() {
                return context.read<CartCubit>().decreaseQuantity(
                  item.product.id,
                );
              });
            },
            onRemove: () {
              _runCartAction(() {
                return context.read<CartCubit>().removeProduct(item.product.id);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.cartEmpty,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(CartState state) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _cartErrorMessage(
                l10n,
                state.errorType,
                fallback: l10n.cartLoadFailed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.read<CartCubit>().loadCart(force: true);
              },
              child: Text(l10n.reload),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(CartState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.total,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'RM ${state.totalPrice.toStringAsFixed(2)}',
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _checkout,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.checkoutCount(state.totalQuantity),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCart() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.clearCart),
          content: Text(l10n.clearCartConfirmation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(l10n.clear),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await _runCartAction(() {
      return context.read<CartCubit>().clearCart();
    });
  }

  Future<void> _runCartAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      if (!mounted) {
        return;
      }

      final state = context.read<CartCubit>().state;

      final l10n = AppLocalizations.of(context);

      final message = _cartErrorMessage(
        l10n,
        state.errorType,
        fallback: l10n.cartActionFailed,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _checkout() async {
    final cartState = context.read<CartCubit>().state;

    final request = CheckoutRequest.cart(
      items: cartState.items.toList(growable: false),
    );

    if (request.items.isEmpty) {
      return;
    }

    final addressRepository = context.read<AddressRepository>();

    final orderRepository = context.read<OrderRepository>();

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

  String _cartErrorMessage(
    AppLocalizations l10n,
    CartErrorType? type, {
    required String fallback,
  }) {
    return switch (type) {
      CartErrorType.loadFailed => l10n.cartLoadFailed,
      CartErrorType.clearFailed => l10n.clearCartFailed,
      CartErrorType.updateFailed => l10n.cartUpdateFailed,
      null => fallback,
    };
  }
}
