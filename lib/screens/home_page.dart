import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/product.dart';
import '../cubits/product/product_cubit.dart';
import '../cubits/product/product_state.dart';
import '../widgets/cart_icon_button.dart';
import 'account_page.dart';
import 'product_details.dart';
import 'product_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF6F7F9);
  static const Color textPrimary = Color(0xFF18181B);
  static const Color textSecondary = Color(0xFF71717A);

  int _bannerIndex = 0;

  final List<String> banners = const [
    'https://picsum.photos/id/26/1200/550',
    'https://picsum.photos/id/96/1200/550',
    'https://picsum.photos/id/119/1200/550',
  ];

  final List<_CategoryItem> categories = const [
    _CategoryItem(
      id: 'phone',
      title: 'æ‰‹æ©Ÿ',
      icon: Icons.phone_android_rounded,
    ),
    _CategoryItem(
      id: 'computer',
      title: 'é›»è…¦',
      icon: Icons.laptop_mac_rounded,
    ),
    _CategoryItem(
      id: 'camera',
      title: 'ç›¸æ©Ÿ',
      icon: Icons.camera_alt_rounded,
    ),
    _CategoryItem(id: 'audio', title: 'éŸ³è¨Š', icon: Icons.headphones_rounded),
    _CategoryItem(
      id: 'gaming',
      title: 'éŠæˆ²',
      icon: Icons.sports_esports_rounded,
    ),
    _CategoryItem(id: 'accessory', title: 'é…ä»¶', icon: Icons.watch_rounded),
    _CategoryItem(id: 'home', title: 'å®¶é›»', icon: Icons.kitchen_rounded),
    _CategoryItem(id: 'all', title: 'å…¨éƒ¨', icon: Icons.grid_view_rounded),
  ];

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
      backgroundColor: background,
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

                _buildFlashSale(
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
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      toolbarHeight: 76,
      titleSpacing: 16,
      title: _buildSearchBar(),
      actions: [
        IconButton(
          tooltip: 'æˆ‘çš„å¸³æˆ¶',
          onPressed: _openAccount,
          icon: const Icon(Icons.person_outline_rounded, color: textPrimary),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: CartIconButton(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Material(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _openScanner,
            borderRadius: BorderRadius.circular(14),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(Icons.qr_code_scanner_rounded, size: 22),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Material(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openSearch,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                height: 46,
                child: Row(
                  children: [
                    SizedBox(width: 14),

                    Icon(Icons.search_rounded, color: textSecondary),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'æœå°‹å•†å“ã€å“ç‰Œ',
                        style: TextStyle(color: textSecondary, fontSize: 14),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CarouselSlider.builder(
              itemCount: banners.length,
              itemBuilder: (context, index, realIndex) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      banners[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE5E7EB),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined),
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

                    const Positioned(
                      left: 22,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TECH WEEK',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'æœ€é«˜å„ªæƒ  40%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ç²¾é¸ç§‘æŠ€å•†å“é™æ™‚å„ªæƒ ',
                            style: TextStyle(color: Colors.white, fontSize: 13),
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
            children: List.generate(banners.length, (index) {
              final selected = index == _bannerIndex;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: selected ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected ? primary : const Color(0xFFD4D4D8),
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
    const items = [
      (title: 'æ¯æ—¥å„ªæƒ ', icon: Icons.local_offer_outlined),
      (title: 'æ–°å“ä¸Šå¸‚', icon: Icons.new_releases_outlined),
      (title: 'ç†±éŠ·æŽ’è¡Œ', icon: Icons.local_fire_department_outlined),
      (title: 'å„ªæƒ åˆ¸', icon: Icons.confirmation_number_outlined),
    ];

    return Container(
      color: Colors.white,
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
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(item.icon, color: primary),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'å•†å“åˆ†é¡ž',
            actionText: 'æŸ¥çœ‹å…¨éƒ¨',
            onPressed: () {
              _openProductList(
                categoryId: 'all',
                categoryTitle: 'å…¨éƒ¨å•†å“',
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
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(category.icon, color: primary, size: 25),
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

  Widget _buildFlashSale(List<Product> products) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFEF4444)),

                const SizedBox(width: 5),

                const Text(
                  'ç†±éŠ·å•†å“',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),

                const Spacer(),

                TextButton(onPressed: () {}, child: const Text('æ›´å¤š')),
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
                return _FlashSaleCard(product: products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      width: 30,
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: textPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPromotionBanner() {
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
        child: const Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'æœƒå“¡å°ˆå±¬å„ªæƒ ',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'åŠ å…¥æœƒå“¡äº«æ›´å¤šæŠ˜æ‰£',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'æœ€æ–°å•†å“',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('æŽƒæåŠŸèƒ½å°šæœªæŽ¥å…¥')));
  }

  void _openSearch() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('æœå°‹é é¢å°šæœªæŽ¥å…¥')));
  }

  Future<void> _openAccount() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AccountPage()),
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _HomePageState.textPrimary,
          ),
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

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
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
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            Text(
              'å·²å”® ${product.sold}',
              style: const TextStyle(
                color: _HomePageState.textSecondary,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 19,
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
                    style: const TextStyle(
                      color: _HomePageState.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'å·²å”® ${product.sold} Â· åº«å­˜ ${product.stock}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: _HomePageState.textSecondary,
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

class _ProductItem {
  const _ProductItem({
    required this.name,
    required this.image,
    required this.price,
    this.oldPrice,
    this.rating = 0,
    this.sold = 0,
  });

  final String name;
  final String image;

  final double price;
  final double? oldPrice;

  final double rating;
  final int sold;
}
