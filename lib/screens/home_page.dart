import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/product/product_cubit.dart';
import '../cubits/product/product_state.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../widgets/cart_icon_button.dart';
import 'account_page.dart';
import 'product_details.dart';
import 'product_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  static const List<String> _banners = [
    'https://picsum.photos/id/26/1200/550',
    'https://picsum.photos/id/96/1200/550',
    'https://picsum.photos/id/119/1200/550',
  ];

  int _bannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productState = context.watch<ProductCubit>().state;

    final products = switch (productState) {
      ProductReady(:final products) => products,
      _ => const <Product>[],
    };

    final bestSellingProducts = List<Product>.of(products)
      ..sort((a, b) => b.sold.compareTo(a.sold));

    final latestProducts = products.take(10).toList(growable: false);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),

          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildBanner(),

                const SizedBox(height: 18),

                _buildQuickActions(),

                const SizedBox(height: 12),

                _buildCategories(),

                const SizedBox(height: 12),

                _buildHotProducts(
                  bestSellingProducts.take(8).toList(growable: false),
                ),

                const SizedBox(height: 12),

                _buildPromotionBanner(),

                const SizedBox(height: 20),

                _buildRecommendationTitle(),

                const SizedBox(height: 12),
              ],
            ),
          ),

          _buildRecommendationGrid(latestProducts),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
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
      title: _buildSearchBar(),
      actions: [
        IconButton(
          tooltip: l10n.myAccount,
          onPressed: _openAccount,
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

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _openScanner,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 22,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 46,
                child: Row(
                  children: [
                    const SizedBox(width: 14),

                    Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        l10n.searchProductsBrands,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CarouselSlider.builder(
              itemCount: _banners.length,
              itemBuilder: (context, index, realIndex) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _banners[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),

                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0x66000000), Colors.transparent],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 22,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.techWeek,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            l10n.bannerDiscount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.bannerTechDeal,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              options: CarouselOptions(
                height: 190,
                viewportFraction: 1,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                onPageChanged: (index, reason) {
                  setState(() {
                    _bannerIndex = index;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              final selected = index == _bannerIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: selected ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    final items = [
      _QuickActionItem(
        title: l10n.dailyDeals,
        icon: Icons.local_offer_outlined,
      ),
      _QuickActionItem(
        title: l10n.newArrivals,
        icon: Icons.new_releases_outlined,
      ),
      _QuickActionItem(
        title: l10n.bestSellers,
        icon: Icons.local_fire_department_outlined,
      ),
      _QuickActionItem(
        title: l10n.coupons,
        icon: Icons.confirmation_number_outlined,
      ),
    ];

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(item.icon, color: colorScheme.primary),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategories() {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    final categories = [
      _CategoryItem(
        id: 'phone',
        title: l10n.categoryPhone,
        icon: Icons.phone_android_rounded,
      ),
      _CategoryItem(
        id: 'computer',
        title: l10n.categoryComputer,
        icon: Icons.laptop_mac_rounded,
      ),
      _CategoryItem(
        id: 'camera',
        title: l10n.categoryCamera,
        icon: Icons.camera_alt_rounded,
      ),
      _CategoryItem(
        id: 'audio',
        title: l10n.categoryAudio,
        icon: Icons.headphones_rounded,
      ),
      _CategoryItem(
        id: 'gaming',
        title: l10n.categoryGaming,
        icon: Icons.sports_esports_rounded,
      ),
      _CategoryItem(
        id: 'accessory',
        title: l10n.categoryAccessory,
        icon: Icons.watch_rounded,
      ),
      _CategoryItem(
        id: 'home',
        title: l10n.categoryHomeAppliance,
        icon: Icons.kitchen_rounded,
      ),
      _CategoryItem(
        id: 'all',
        title: l10n.categoryAll,
        icon: Icons.grid_view_rounded,
      ),
    ];

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: l10n.productCategories,
            actionText: l10n.viewAll,
            onPressed: () {
              _openProductList(
                categoryId: 'all',
                categoryTitle: l10n.allProducts,
              );
            },
          ),

          const SizedBox(height: 18),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 20,
              crossAxisSpacing: 10,
              mainAxisExtent: 82,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _openProductList(
                    categoryId: category.id,
                    categoryTitle: category.title,
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        category.icon,
                        color: colorScheme.primary,
                        size: 25,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      category.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHotProducts(List<Product> products) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: colorScheme.error),

                const SizedBox(width: 5),

                Text(
                  l10n.hotProducts,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                TextButton(onPressed: () {}, child: Text(l10n.more)),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (_, __) {
                return const SizedBox(width: 12);
              },
              itemBuilder: (context, index) {
                return _HotProductCard(product: products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBanner() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 115,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF111827), Color(0xFF374151)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.memberExclusive,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.joinMemberDiscount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationTitle() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.latestProducts,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  SliverPadding _buildRecommendationGrid(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          return _ProductCard(product: products[index]);
        }, childCount: products.length),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
      ),
    );
  }

  Future<void> _openProductList({
    required String categoryId,
    required String categoryTitle,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ProductList(
            categoryId: categoryId,
            categoryTitle: categoryTitle,
          );
        },
      ),
    );
  }

  void _openScanner() {
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.scannerComingSoon)));
  }

  void _openSearch() {
    final l10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.searchComingSoon)));
  }

  Future<void> _openAccount() async {
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionText,
    required this.onPressed,
  });

  final String title;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        TextButton(
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(actionText),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotProductCard extends StatelessWidget {
  const _HotProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: 145,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) {
                return ProductDetails(product: product);
              },
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(product.image, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 5),

            Text(
              'RM ${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            Text(
              l10n.soldCount(product.sold),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) {
                return ProductDetails(product: product);
              },
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(product.image, fit: BoxFit.cover),

                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 19,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    'RM ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    l10n.soldAndStock(product.sold, product.stock),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

class _QuickActionItem {
  const _QuickActionItem({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
