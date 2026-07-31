import 'package:flutter/material.dart';

import '../models/product.dart';
import '../widgets/cart_icon_button.dart';
import 'product_card.dart';
import 'product_details.dart';

class ProductList extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;

  const ProductList({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  State<ProductList> createState() {
    return _ProductListState();
  }
}

class _ProductListState extends State<ProductList> {
  List<Product> get categoryProducts {
    return products.where((product) {
      return product.categoryId == widget.categoryId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = categoryProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        actions: const [CartIconButton()],
      ),
      body: filteredProducts.isEmpty
          ? _buildEmptyView()
          : _buildProductGrid(filteredProducts),
    );
  }

  Widget _buildProductGrid(List<Product> filteredProducts) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];

        return ProductCard(
          product: product,
          onTap: () {
            _openDetails(product);
          },
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            '${widget.categoryTitle}暫時沒有商品',
            style: const TextStyle(color: Colors.grey, fontSize: 17),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(Product product) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ProductDetails(product: product);
        },
      ),
    );
  }
}
