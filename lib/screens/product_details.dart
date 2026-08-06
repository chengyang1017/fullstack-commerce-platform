import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/checkout_request.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../repositories/address_repository.dart';
import '../repositories/order_repository.dart';
import '../widgets/cart_icon_button.dart';
import 'cart_page.dart';
import 'checkout_page.dart';

class ProductDetails extends StatefulWidget {
  final Product product;

  const ProductDetails({
    super.key,
    required this.product,
  });

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
    return AppBar(
      title: Text(
        product.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
          icon: Icon(
            _isFavorite
                ? Icons.favorite
                : Icons.favorite_border,
            color: _isFavorite ? Colors.red : null,
          ),
        ),
        const CartIconButton(),
      ],
    );
  }

  Widget _buildBody() {
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
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const ColoredBox(
                  color: Color(0xFFF2F2F2),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'RM ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.red,
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
                  '已售 ${product.sold}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final quantity = context.select(
      (CartProvider cart) {
        return cart.quantityOf(product.id);
      },
    );

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
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
              child: OutlinedButton(
                onPressed: _addToCart,
                child: Text(
                  quantity == 0
                      ? '加入購物車'
                      : '加入購物車 ($quantity)',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _buyNow,
                child: const Text('立即購買'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    try {
      await context
          .read<CartProvider>()
          .addProduct(product);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} 已加入購物車'),
          action: SnackBarAction(
            label: '查看',
            onPressed: _openCart,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      final message =
          context.read<CartProvider>().errorMessage ??
          '加入購物車失敗';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _buyNow() async {
    final addressRepository =
        context.read<AddressRepository>();

    final orderRepository =
        context.read<OrderRepository>();

    final request = CheckoutRequest.buyNow(
      items: [
        CartItem(
          product: product,
          quantity: 1,
        ),
      ],
    );

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
