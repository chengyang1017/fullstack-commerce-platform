import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HomeCategories extends StatelessWidget {
  const HomeCategories({
    super.key,
    required this.onCategorySelected,
    required this.onViewAll,
  });

  final void Function(String categoryId, String categoryTitle)
  onCategorySelected;

  final VoidCallback onViewAll;

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
        id: 'gaming',
        title: l10n.categoryGaming,
        icon: Icons.sports_esports_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.productCategories,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),

              TextButton(
                onPressed: onViewAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.viewAll),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (var index = 0; index < categories.length; index++) ...[
                Expanded(
                  child: _CategoryCard(
                    category: categories[index],
                    onTap: () {
                      onCategorySelected(
                        categories[index].id,
                        categories[index].title,
                      );
                    },
                  ),
                ),

                if (index != categories.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 118,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
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
                      size: 27,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
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
