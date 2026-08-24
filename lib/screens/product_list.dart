import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/product/product_cubit.dart';
import '../cubits/product/product_state.dart';
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
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductInitial || state is ProductLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.categoryTitle),
              actions: const [CartIconButton()],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProductError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.categoryTitle),
              actions: const [CartIconButton()],
            ),
            body: _buildErrorView(state.message),
          );
        }

        final products = (state as ProductReady).products;

        final filteredProducts = _productsByCategory(products);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.categoryTitle),
            actions: const [CartIconButton()],
          ),
          body: RefreshIndicator(
            onRefresh: context.read<ProductCubit>().refreshProducts,
            child: filteredProducts.isEmpty
                ? _buildEmptyView()
                : _buildProductGrid(filteredProducts),
          ),
        );
      },
    );
  }

  List<Product> _productsByCategory(List<Product> products) {
    if (widget.categoryId.isEmpty || widget.categoryId == 'all') {
      return products;
    }

    return products
        .where((product) => product.categoryId == widget.categoryId)
        .toList(growable: false);
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

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              context.read<ProductCubit>().refreshProducts();
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
