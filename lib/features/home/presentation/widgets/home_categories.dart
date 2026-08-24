import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HomeCategories extends StatelessWidget {
  const HomeCategories({super.key, required this.onCategorySelected});

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
      _CategoryItem(
        id: 'all',
        title: l10n.categoryAll,
        icon: Icons.apps_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _SectionHeader(
            title: l10n.productCategories,
            actionText: l10n.viewAll,
            onPressed: () {
              onCategorySelected('all', l10n.allProducts);
            },
          ),

          const SizedBox(height: 18),

          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 18,
              mainAxisExtent: 78,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];

              return _CategoryButton(
                category: category,
                onTap: () {
                  onCategorySelected(category.id, category.title);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.category, required this.onTap});

  final _CategoryItem category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, size: 22, color: colorScheme.primary),
            ),

            const SizedBox(height: 7),

            Text(
              category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onPressed,
  });

  final String title;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),

        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
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
