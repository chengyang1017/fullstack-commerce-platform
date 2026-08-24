import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/product.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../widgets/product_card.dart';
import 'product_details.dart';

enum ProductListMode { category, latest, bestSelling }

class ProductList extends StatefulWidget {
  const ProductList({
    super.key,
    required this.categoryId,
    required this.categoryTitle,
    this.mode = ProductListMode.category,
  });

  final String categoryId;
  final String categoryTitle;
  final ProductListMode mode;

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
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProductError) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: _buildErrorView(state.type),
          );
        }

        final products = (state as ProductReady).products;

        final displayedProducts = _buildDisplayedProducts(products);

        return Scaffold(
          appBar: _buildAppBar(),
          body: RefreshIndicator(
            onRefresh: context.read<ProductCubit>().refreshProducts,
            child: displayedProducts.isEmpty
                ? _buildEmptyView()
                : _buildProductGrid(displayedProducts),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.categoryTitle),
      actions: const [CartIconButton()],
    );
  }

  List<Product> _buildDisplayedProducts(List<Product> products) {
    return switch (widget.mode) {
      ProductListMode.category => _productsByCategory(products),

      ProductListMode.latest => List<Product>.unmodifiable(products),

      ProductListMode.bestSelling => _bestSellingProducts(products),
    };
  }

  List<Product> _productsByCategory(List<Product> products) {
    if (widget.categoryId.isEmpty || widget.categoryId == 'all') {
      return List<Product>.unmodifiable(products);
    }

    return products
        .where((product) => product.categoryId == widget.categoryId)
        .toList(growable: false);
  }

  List<Product> _bestSellingProducts(List<Product> products) {
    final sorted = List<Product>.of(products);

    sorted.sort((left, right) => right.sold.compareTo(left.sold));

    return List<Product>.unmodifiable(sorted);
  }

  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.65,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        return ProductCard(
          product: product,
          onTap: () {
            _openDetails(product);
          },
        );
      },
    );
  }

  Widget _buildErrorView(ProductErrorType type) {
    final l10n = AppLocalizations.of(context);

    final message = switch (type) {
      ProductErrorType.loadFailed => l10n.productLoadFailed,
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                context.read<ProductCubit>().refreshProducts();
              },
              child: Text(l10n.reload),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 72,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.categoryNoProducts(widget.categoryTitle),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 17,
                  ),
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
