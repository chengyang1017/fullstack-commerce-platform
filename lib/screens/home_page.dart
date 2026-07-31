import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../widgets/cart_icon_button.dart';
import 'product_list.dart';
import 'account_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final List<String> images = [
    'https://picsum.photos/id/10/800/500',
    'https://picsum.photos/id/20/800/500',
    'https://picsum.photos/id/30/800/500',
  ];

  final List<({String id, String title, IconData icon})> categories = [
    (id: 'phone', title: '手機', icon: Icons.phone_android),
    (id: 'computer', title: '電腦', icon: Icons.computer),
    (id: 'camera', title: '相機', icon: Icons.camera_alt),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCarousel(),
              Expanded(child: _buildCategoriesView()),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: _openScanner,
        icon: const Icon(Icons.qr_code_scanner),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: TextField(
          readOnly: true,
          onTap: _openSearch,
          decoration: InputDecoration(
            hintText: '搜尋商品',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: '我的',
          onPressed: _openAccount,
          icon: const Icon(Icons.person_outline),
        ),
        const CartIconButton(),
      ],
    );
  }

  Widget _buildCarousel() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CarouselSlider(
          items: images.map((url) {
            return Image.network(
              url,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0xFFF2F2F2),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            );
          }).toList(),
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1,
            autoPlay: true,
            enlargeCenterPage: false,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '分類',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return _buildCategoryCard(
                  id: category.id,
                  title: category.title,
                  icon: category.icon,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String id,
    required String title,
    required IconData icon,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _openProductList(categoryId: id, categoryTitle: title);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(title),
          ],
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
        builder: (context) {
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
    ).showSnackBar(const SnackBar(content: Text('掃描功能尚未接入')));
  }

  void _openSearch() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('搜尋頁面尚未接入')));
  }

  Future<void> _openAccount() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const AccountPage();
        },
      ),
    );
  }
}
