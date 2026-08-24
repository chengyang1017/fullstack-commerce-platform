import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../product/domain/models/product.dart';

class HomeHotProducts extends StatelessWidget {
  const HomeHotProducts({
    super.key,
    required this.products,
    required this.onProductTap,
    required this.onMorePressed,
  });

  final List<Product> products;

  final void Function(Product product) onProductTap;

  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final displayedProducts = products.take(6).toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.bestSellers,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),

              TextButton(onPressed: onMorePressed, child: Text(l10n.more)),
            ],
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayedProducts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = displayedProducts[index];

              return _HotProductItem(
                rank: index + 1,
                product: product,
                onTap: () {
                  onProductTap(product);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HotProductItem extends StatelessWidget {
  const _HotProductItem({
    required this.rank,
    required this.product,
    required this.onTap,
  });

  final int rank;
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return SizedBox(
      width: 124,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 124,
                    height: 116,
                    child: Image.network(
                      product.image,
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
                  ),
                ),

                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Text(
              product.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 4),

            Text(
              'RM ${product.price.toStringAsFixed(2)}',
              maxLines: 1,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              l10n.soldCount(product.sold),
              maxLines: 1,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
