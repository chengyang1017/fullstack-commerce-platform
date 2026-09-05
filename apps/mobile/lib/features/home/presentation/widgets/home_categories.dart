import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../category/domain/models/product_category.dart';
import '../../../category/presentation/cubit/category_cubit.dart';
import '../../../category/presentation/cubit/category_state.dart';
import '../../../category/presentation/widgets/category_icon_badge.dart';

class HomeCategories extends StatelessWidget {
  const HomeCategories({
    super.key,
    required this.onCategorySelected,
    required this.onViewAll,
  });

  final void Function(
    String categoryId,
    String categoryTitle,
  ) onCategorySelected;

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.productCategories,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.viewAll),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, state) {
            if (state is CategoryInitial ||
                state is CategoryLoading) {
              return const SizedBox(
                height: 118,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is CategoryError) {
              return SizedBox(
                height: 118,
                child: Center(
                  child: IconButton(
                    onPressed: () {
                      context
                          .read<CategoryCubit>()
                          .refreshCategories();
                    },
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                  ),
                ),
              );
            }

            final categories = (state as CategoryReady)
                .categories
                .take(3)
                .toList(growable: false);

            if (categories.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Row(
                children: [
                  for (
                    var index = 0;
                    index < categories.length;
                    index++
                  ) ...[
                    Expanded(
                      child: _CategoryCard(
                        category: categories[index],
                        onTap: () {
                          onCategorySelected(
                          categories[index].id,
                          localizedCategoryName(l10n, categories[index]),
                        );
                        },
                      ),
                    ),
                    if (index != categories.length - 1)
                      const SizedBox(width: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  final ProductCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 118,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              10,
              8,
              10,
              10,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: CategoryIconBadge(
                      category: category,
                      size: 64,
                      iconSize: 35,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                SizedBox(
                  width: double.infinity,
                  child: Text(
                    localizedCategoryName(l10n, category),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
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

String localizedCategoryName(
  AppLocalizations l10n,
  ProductCategory category,
) {
  switch (category.id) {
    case 'phone':
      return l10n.categoryPhone;

    default:
      return category.name;
  }
}