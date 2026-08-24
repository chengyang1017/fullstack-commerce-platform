import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../../../product/domain/models/product.dart';
import '../../../product/presentation/cubit/product_cubit.dart';
import '../../../product/presentation/cubit/product_state.dart';
import '../../../product/presentation/pages/product_details.dart';
import '../../../product/presentation/pages/product_list.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_coupon_strip.dart';
import '../widgets/home_hot_products.dart';
import '../widgets/home_new_arrivals.dart';
import '../widgets/home_product_status.dart';
import '../widgets/home_search_bar.dart';
import 'all_categories_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final productState = context.watch<ProductCubit>().state;

    final l10n = AppLocalizations.of(context);

    final readyProducts = switch (productState) {
      ProductReady(:final products) => products,

      _ => const <Product>[],
    };

    final bestSellingProducts = List<Product>.of(readyProducts)
      ..sort((a, b) => b.sold.compareTo(a.sold));

    final newArrivalProducts = readyProducts.take(4).toList(growable: false);

    final hasProducts = readyProducts.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 8),

                const HomeBanner(),

                const SizedBox(height: 22),

                HomeCouponStrip(
                  onCouponTap: () {
                    _showComingSoon(context, l10n.couponsComingSoon);
                  },
                ),

                const SizedBox(height: 24),

                HomeCategories(
                  onCategorySelected: (categoryId, categoryTitle) {
                    _openProductList(
                      context,
                      categoryId: categoryId,
                      categoryTitle: categoryTitle,
                    );
                  },
                  onViewAll: () {
                    _openAllCategories(context);
                  },
                ),

                const SizedBox(height: 26),

                switch (productState) {
                  ProductInitial() => const HomeProductLoading(),

                  ProductLoading() => const HomeProductLoading(),

                  ProductError(:final type) => HomeProductError(
                    type: type,
                    onRetry: () {
                      context.read<ProductCubit>().refreshProducts();
                    },
                  ),

                  ProductReady() when !hasProducts => HomeProductEmpty(
                    message: l10n.noProductsAvailable,
                  ),

                  ProductReady() => Column(
                    children: [
                      HomeNewArrivals(
                        products: newArrivalProducts,
                        onProductTap: (product) {
                          _openProductDetails(context, product);
                        },
                        onViewAll: () {
                          _openProductList(
                            context,
                            categoryId: 'all',
                            categoryTitle: l10n.newArrivals,
                            mode: ProductListMode.latest,
                          );
                        },
                      ),

                      const SizedBox(height: 26),

                      HomeHotProducts(
                        products: bestSellingProducts,
                        onProductTap: (product) {
                          _openProductDetails(context, product);
                        },
                        onMorePressed: () {
                          _openProductList(
                            context,
                            categoryId: 'all',
                            categoryTitle: l10n.bestSellers,
                            mode: ProductListMode.bestSelling,
                          );
                        },
                      ),
                    ],
                  ),
                },

                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surface,
      elevation: 0,
      toolbarHeight: 72,
      titleSpacing: 12,
      title: HomeSearchBar(
        onScannerTap: () {
          _openScanner(context);
        },
        onSearchTap: () {
          _openSearch(context);
        },
      ),
      actions: [
        IconButton(
          tooltip: l10n.myAccount,
          onPressed: () {
            _openAccount(context);
          },
          icon: Icon(
            Icons.person_outline_rounded,
            color: colorScheme.onSurface,
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(right: 6),
          child: CartIconButton(),
        ),
      ],
    );
  }

  Future<void> _openAllCategories(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return AllCategoriesPage(
            onCategorySelected: (categoryId, categoryTitle) {
              Navigator.pop(context);

              _openProductList(
                context,
                categoryId: categoryId,
                categoryTitle: categoryTitle,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openProductList(
    BuildContext context, {
    required String categoryId,
    required String categoryTitle,
    ProductListMode mode = ProductListMode.category,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ProductList(
            categoryId: categoryId,
            categoryTitle: categoryTitle,
            mode: mode,
          );
        },
      ),
    );
  }

  Future<void> _openProductDetails(
    BuildContext context,
    Product product,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ProductDetails(product: product);
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openScanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    _showComingSoon(context, l10n.scannerComingSoon);
  }

  void _openSearch(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    _showComingSoon(context, l10n.searchComingSoon);
  }

  Future<void> _openAccount(BuildContext context) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return const AccountPage();
        },
      ),
    );
  }
}
