import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../product/presentation/cubit/product_cubit.dart';
import '../../../product/presentation/cubit/product_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../product/domain/models/product.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_hot_products.dart';
import '../widgets/home_product_card.dart';
import '../widgets/home_product_status.dart';
import '../widgets/home_quick_actions.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_promotion_card.dart';
import '../../../account/presentation/pages/account_page.dart';
import '../../../product/presentation/pages/product_details.dart';
import '../../../product/presentation/pages/product_list.dart';

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

    final latestProducts = readyProducts.take(10).toList(growable: false);

    final hasProducts = readyProducts.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const HomeBanner(),

                const SizedBox(height: 16),

                HomeQuickActions(
                  onDailyDealsTap: () {
                    _showComingSoon(context, l10n.dailyDealsComingSoon);
                  },
                  onNewArrivalsTap: () {
                    _openProductList(
                      context,
                      categoryId: 'all',
                      categoryTitle: l10n.newArrivals,
                      mode: ProductListMode.latest,
                    );
                  },
                  onBestSellersTap: () {
                    _openProductList(
                      context,
                      categoryId: 'all',
                      categoryTitle: l10n.bestSellers,
                      mode: ProductListMode.bestSelling,
                    );
                  },
                  onCouponsTap: () {
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
                ),

                const SizedBox(height: 18),

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

                  ProductReady() => HomeHotProducts(
                    products: bestSellingProducts
                        .take(8)
                        .toList(growable: false),
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
                },

                const SizedBox(height: 8),

                const HomePromotionCard(),

                if (hasProducts) ...[
                  const SizedBox(height: 24),

                  const _HomeRecommendationTitle(),

                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),

          if (hasProducts) _buildRecommendationGrid(context, latestProducts),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
      toolbarHeight: 76,
      titleSpacing: 16,
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
          padding: EdgeInsets.only(right: 8),
          child: CartIconButton(),
        ),
      ],
    );
  }

  Widget _buildRecommendationGrid(
    BuildContext context,
    List<Product> products,
  ) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;

        final crossAxisCount = switch (width) {
          >= 1100 => 5,
          >= 800 => 4,
          >= 600 => 3,
          _ => 2,
        };

        final childAspectRatio = switch (crossAxisCount) {
          >= 4 => 0.72,
          3 => 0.70,
          _ => 0.68,
        };

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];

              return HomeProductCard(
                product: product,
                onTap: () {
                  _openProductDetails(context, product);
                },
              );
            }, childCount: products.length),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
          ),
        );
      },
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

class _HomeRecommendationTitle extends StatelessWidget {
  const _HomeRecommendationTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.latestProducts,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
