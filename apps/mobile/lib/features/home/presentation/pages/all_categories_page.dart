import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({super.key, required this.onCategorySelected});

  final void Function(String categoryId, String categoryTitle)
  onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final categories = [
      _CategoryItem(
        id: 'phone',
        title: l10n.categoryPhone,
        icon: Icons.phone_iphone_rounded,
      ),
      _CategoryItem(
        id: 'computer',
        title: l10n.categoryComputer,
        icon: Icons.laptop_mac_rounded,
      ),
      _CategoryItem(
        id: 'camera',
        title: l10n.categoryCamera,
        icon: Icons.photo_camera_rounded,
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
        icon: Icons.home_rounded,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.productCategories)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];

          return _CategoryCard(
            category: category,
            onTap: () {
              onCategorySelected(category.id, category.title);
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final _CategoryItem category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const Spacer(),

              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    category.icon,
                    size: 25,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
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
