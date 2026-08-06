import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
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
  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    if (productProvider.status == ProductStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (productProvider.status == ProductStatus.loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryTitle),
          actions: const [CartIconButton()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (productProvider.status == ProductStatus.error) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.categoryTitle),
          actions: const [CartIconButton()],
        ),
        body: _buildErrorView(productProvider),
      );
    }

    final filteredProducts = productProvider.productsByCategory(
      widget.categoryId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
        actions: const [CartIconButton()],
      ),
      body: RefreshIndicator(
        onRefresh: productProvider.refreshProducts,
        child: filteredProducts.isEmpty
            ? _buildEmptyView()
            : _buildProductGrid(filteredProducts),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> filteredProducts) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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

  Widget _buildErrorView(ProductProvider productProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            productProvider.errorMessage ?? '加载商品失败',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              productProvider.refreshProducts();
            },
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 72,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.categoryTitle}暫時沒有商品',
                  style: const TextStyle(color: Colors.grey, fontSize: 17),
                ),
              ],
            ),
          ),
        ),
      ],
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
