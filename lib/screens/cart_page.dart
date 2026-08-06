import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/checkout_request.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../repositories/address_repository.dart';
import '../repositories/order_repository.dart';
import '../widgets/cart_item_tile.dart';
import 'checkout_page.dart';

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
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('購物車 (${cart.totalQuantity})'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: _confirmClearCart,
              child: const Text('清空'),
            ),
        ],
      ),
      body: _buildBody(cart),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _buildCheckoutBar(cart),
    );
  }

  Widget _buildBody(CartProvider cart) {
    if (cart.isLoading && cart.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (cart.status == CartStatus.error && cart.isEmpty) {
      return _buildErrorView(cart);
    }

    if (cart.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () {
        return cart.loadCart(force: true);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: cart.items.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 8);
        },
        itemBuilder: (context, index) {
          final item = cart.items[index];

          return CartItemTile(
            key: ValueKey(item.product.id),
            item: item,
            onIncrease: () {
              _runCartAction(
                () => context
                    .read<CartProvider>()
                    .increaseQuantity(item.product.id),
              );
            },
            onDecrease: () {
              _runCartAction(
                () => context
                    .read<CartProvider>()
                    .decreaseQuantity(item.product.id),
              );
            },
            onRemove: () {
              _runCartAction(
                () => context
                    .read<CartProvider>()
                    .removeProduct(item.product.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '購物車還是空的',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(CartProvider cart) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              cart.errorMessage ?? '購物車載入失敗',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                cart.loadCart(force: true);
              },
              child: const Text('重新載入'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar(CartProvider cart) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    '總計',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'RM ${cart.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _checkout,
              child: Text(
                '結算 (${cart.totalQuantity})',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('清空購物車'),
          content: const Text(
            '確定要刪除購物車中的所有商品嗎？',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await _runCartAction(
      () => context.read<CartProvider>().clearCart(),
    );
  }

  Future<void> _runCartAction(
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (!mounted) return;

      final message =
          context.read<CartProvider>().errorMessage ??
          '購物車操作失敗';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();

    final request = CheckoutRequest.cart(
      items: cart.items.toList(growable: false),
    );

    if (request.items.isEmpty) {
      return;
    }

    final addressRepository =
        context.read<AddressRepository>();

    final orderRepository =
        context.read<OrderRepository>();

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ChangeNotifierProvider(
            create: (context) {
              return CheckoutProvider(
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
}
