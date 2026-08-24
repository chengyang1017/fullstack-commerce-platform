import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../widgets/cart_icon_button.dart';
import 'account_page.dart';
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
      title: '手機',
      icon: Icons.phone_android_rounded,
    ),
    _CategoryItem(
      id: 'computer',
      title: '電腦',
      icon: Icons.laptop_mac_rounded,
    ),
    _CategoryItem(
      id: 'camera',
      title: '相機',
      icon: Icons.camera_alt_rounded,
    ),
    _CategoryItem(
      id: 'audio',
      title: '音訊',
      icon: Icons.headphones_rounded,
    ),
    _CategoryItem(
      id: 'gaming',
      title: '遊戲',
      icon: Icons.sports_esports_rounded,
    ),
    _CategoryItem(
      id: 'accessory',
      title: '配件',
      icon: Icons.watch_rounded,
    ),
    _CategoryItem(
      id: 'home',
      title: '家電',
      icon: Icons.kitchen_rounded,
    ),
    _CategoryItem(
      id: 'all',
      title: '全部',
      icon: Icons.grid_view_rounded,
    ),
  ];

  final List<_ProductItem> flashSaleProducts = const [
    _ProductItem(
      name: 'Wireless Headphones',
      image: 'https://picsum.photos/id/3/500/500',
      price: 299,
      oldPrice: 399,
    ),
    _ProductItem(
      name: 'Smart Watch Pro',
      image: 'https://picsum.photos/id/20/500/500',
      price: 189,
      oldPrice: 259,
    ),
    _ProductItem(
      name: 'Mechanical Keyboard',
      image: 'https://picsum.photos/id/30/500/500',
      price: 149,
      oldPrice: 199,
    ),
    _ProductItem(
      name: 'Portable Speaker',
      image: 'https://picsum.photos/id/39/500/500',
      price: 99,
      oldPrice: 139,
    ),
  ];

  final List<_ProductItem> recommendedProducts = const [
    _ProductItem(
      name: 'iPhone Compatible Fast Charger',
      image: 'https://picsum.photos/id/48/600/600',
      price: 59,
      rating: 4.8,
      sold: 1240,
    ),
    _ProductItem(
      name: 'Ultra Slim Laptop Stand',
      image: 'https://picsum.photos/id/60/600/600',
      price: 89,
      rating: 4.9,
      sold: 821,
    ),
    _ProductItem(
      name: 'Bluetooth Wireless Earbuds',
      image: 'https://picsum.photos/id/76/600/600',
      price: 129,
      rating: 4.7,
      sold: 2341,
    ),
    _ProductItem(
      name: '4K Action Camera',
      image: 'https://picsum.photos/id/91/600/600',
      price: 349,
      rating: 4.6,
      sold: 453,
    ),
    _ProductItem(
      name: 'Gaming Mouse RGB',
      image: 'https://picsum.photos/id/106/600/600',
      price: 79,
      rating: 4.8,
      sold: 1890,
    ),
    _ProductItem(
      name: 'USB-C Multiport Hub',
      image: 'https://picsum.photos/id/180/600/600',
      price: 109,
      rating: 4.9,
      sold: 675,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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

                _buildFlashSale(),

                const SizedBox(height: 12),

                _buildPromotionBanner(),

                const SizedBox(height: 20),

                _buildRecommendationTitle(),

                const SizedBox(height: 12),
              ],
            ),
          ),

          _buildRecommendationGrid(),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
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
          tooltip: '我的帳戶',
          onPressed: _openAccount,
          icon: const Icon(
            Icons.person_outline_rounded,
            color: textPrimary,
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
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 22,
              ),
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

                    Icon(
                      Icons.search_rounded,
                      color: textSecondary,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        '搜尋商品、品牌',
                        style: TextStyle(
                          color: textSecondary,
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CarouselSlider.builder(
              itemCount: banners.length,
              itemBuilder: (
                context,
                index,
                realIndex,
              ) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      banners[index],
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          color: const Color(0xFFE5E7EB),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                          ),
                        );
                      },
                    ),

                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0x66000000),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const Positioned(
                      left: 22,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                            '最高優惠 40%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '精選科技商品限時優惠',
                            style: TextStyle(
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
                autoPlayInterval:
                    const Duration(seconds: 5),
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
            children: List.generate(
              banners.length,
              (index) {
                final selected = index == _bannerIndex;

                return AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 250),
                  width: selected ? 22 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? primary
                        : const Color(0xFFD4D4D8),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    const items = [
      (
        title: '每日優惠',
        icon: Icons.local_offer_outlined,
      ),
      (
        title: '新品上市',
        icon: Icons.new_releases_outlined,
      ),
      (
        title: '熱銷排行',
        icon: Icons.local_fire_department_outlined,
      ),
      (
        title: '優惠券',
        icon: Icons.confirmation_number_outlined,
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        color: primary,
                      ),
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
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: '商品分類',
            actionText: '查看全部',
            onPressed: () {
              _openProductList(
                categoryId: 'all',
                categoryTitle: '全部商品',
              );
            },
          ),

          const SizedBox(height: 18),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
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
                        borderRadius:
                            BorderRadius.circular(17),
                      ),
                      child: Icon(
                        category.icon,
                        color: primary,
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

  Widget _buildFlashSale() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 18,
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFEF4444),
                ),

                const SizedBox(width: 5),

                const Text(
                  '限時優惠',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(width: 12),

                _buildTimeBox('02'),
                const Text(' : '),
                _buildTimeBox('18'),
                const Text(' : '),
                _buildTimeBox('46'),

                const Spacer(),

                TextButton(
                  onPressed: () {},
                  child: const Text('更多'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              itemCount: flashSaleProducts.length,
              separatorBuilder: (_, __) {
                return const SizedBox(width: 12);
              },
              itemBuilder: (context, index) {
                return _FlashSaleCard(
                  product: flashSaleProducts[index],
                );
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
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 115,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF111827),
              Color(0xFF374151),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '會員專屬優惠',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '加入會員享更多折扣',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
            ),
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
          '為你推薦',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ),
    );
  }

  SliverPadding _buildRecommendationGrid() {
    return SliverPadding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _ProductCard(
              product: recommendedProducts[index],
            );
          },
          childCount: recommendedProducts.length,
        ),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('掃描功能尚未接入'),
      ),
    );
  }

  void _openSearch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('搜尋頁面尚未接入'),
      ),
    );
  }

  Future<void> _openAccount() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const AccountPage(),
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
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlashSaleCard extends StatelessWidget {
  const _FlashSaleCard({
    required this.product,
  });

  final _ProductItem product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  product.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
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

            if (product.oldPrice != null)
              Text(
                'RM ${product.oldPrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _HomePageState.textSecondary,
                  decoration:
                      TextDecoration.lineThrough,
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
  const _ProductCard({
    required this.product,
  });

  final _ProductItem product;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.image,
                    fit: BoxFit.cover,
                  ),

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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
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

                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFF59E0B),
                      ),

                      const SizedBox(width: 3),

                      Text(
                        '${product.rating}',
                        style: const TextStyle(
                          fontSize: 11,
                          color:
                              _HomePageState.textSecondary,
                        ),
                      ),

                      const SizedBox(width: 7),

                      Text(
                        '已售 ${product.sold}',
                        style: const TextStyle(
                          fontSize: 11,
                          color:
                              _HomePageState.textSecondary,
                        ),
                      ),
                    ],
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