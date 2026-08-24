import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/cart_item.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    final colorScheme =
        Theme.of(context).colorScheme;

    final l10n =
        AppLocalizations.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(
          12,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _ProductImage(
              imageUrl: product.image,
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'RM ${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                          colorScheme.primary,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    l10n.cartItemSubtotal(
                      item.subtotal
                          .toStringAsFixed(
                        2,
                      ),
                    ),
                    style: TextStyle(
                      color: colorScheme
                          .onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Row(
                    children: [
                      _QuantityButton(
                        icon: Icons.remove,
                        onPressed:
                            onDecrease,
                      ),

                      SizedBox(
                        width: 42,
                        child: Text(
                          '${item.quantity}',
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),

                      _QuantityButton(
                        icon: Icons.add,
                        onPressed:
                            onIncrease,
                      ),

                      const Spacer(),

                      IconButton(
                        tooltip:
                            l10n.delete,
                        onPressed:
                            onRemove,
                        icon: Icon(
                          Icons
                              .delete_outline,
                          color:
                              colorScheme
                                  .error,
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

class _ProductImage
    extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        8,
      ),
      child: Image.network(
        imageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return SizedBox(
            width: 100,
            height: 100,
            child: ColoredBox(
              color: colorScheme
                  .surfaceContainerHighest,
              child: Icon(
                Icons
                    .broken_image_outlined,
                color: colorScheme
                    .onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuantityButton
    extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          icon,
          size: 18,
        ),
      ),
    );
  }
}