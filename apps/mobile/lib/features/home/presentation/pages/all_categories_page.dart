import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../category/domain/models/product_category.dart';
import '../../../category/presentation/cubit/category_cubit.dart';
import '../../../category/presentation/cubit/category_state.dart';
import '../../../category/presentation/widgets/category_icon_badge.dart';

class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({
    super.key,
    required this.onCategorySelected,
  });

  final void Function(
    String categoryId,
    String categoryTitle,
  ) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productCategories),
      ),
      body: BlocBuilder<CategoryCubit, CategoryState>(
        builder: (context, state) {
          if (state is CategoryInitial ||
              state is CategoryLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is CategoryError) {
            return Center(
              child: FilledButton.icon(
                onPressed: () {
                  context
                      .read<CategoryCubit>()
                      .refreshCategories();
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: Text(l10n.reload),
              ),
            );
          }

          final categories =
              (state as CategoryReady).categories;

          if (categories.isEmpty) {
            return Center(
              child: Text(
                l10n.noProductsAvailable,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: context
                .read<CategoryCubit>()
                .refreshCategories,
            child: GridView.builder(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                    onCategorySelected(
                      category.id,
                      category.name,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
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

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  category.name,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: CategoryIconBadge(
                    category: category,
                    size: 74,
                    iconSize: 40,
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
