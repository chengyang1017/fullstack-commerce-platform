import 'package:flutter/material.dart';

import '../../domain/models/product_category.dart';

class CategoryIconBadge extends StatelessWidget {
  const CategoryIconBadge({
    super.key,
    required this.category,
    this.size = 52,
    this.iconSize = 27,
  });

  final ProductCategory category;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final start = _parseHexColor(
      category.iconColorStart,
      const Color(0xFF7C3AED),
    );
    final end = _parseHexColor(
      category.iconColorEnd,
      const Color(0xFF06B6D4),
    );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            start.withValues(alpha: 0.18),
            end.withValues(alpha: 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.31),
        border: Border.all(
          color: start.withValues(alpha: 0.18),
        ),
      ),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [start, end],
          ).createShader(bounds);
        },
        child: Icon(
          _iconForName(category.iconName),
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

IconData _iconForName(String name) {
  switch (name) {
    case 'devices':
      return Icons.devices_rounded;
    case 'cable':
      return Icons.cable_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'gaming':
      return Icons.sports_esports_rounded;
    case 'shopping_bag':
      return Icons.shopping_bag_rounded;
    case 'phone':
      return Icons.phone_android_rounded;
    case 'laptop':
      return Icons.laptop_mac_rounded;
    case 'headphones':
      return Icons.headphones_rounded;
    case 'watch':
      return Icons.watch_rounded;
    case 'chair':
      return Icons.chair_rounded;
    case 'kitchen':
      return Icons.kitchen_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'sports':
      return Icons.sports_basketball_rounded;
    case 'spa':
      return Icons.spa_rounded;
    case 'pets':
      return Icons.pets_rounded;
    case 'gift':
      return Icons.card_giftcard_rounded;
    case 'camera':
      return Icons.photo_camera_rounded;
    case 'car':
      return Icons.directions_car_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'category':
    default:
      return Icons.category_rounded;
  }
}

Color _parseHexColor(
  String value,
  Color fallback,
) {
  final normalized = value.trim();
  final match = RegExp(r'^#[0-9A-Fa-f]{6}$')
      .firstMatch(normalized);

  if (match == null) {
    return fallback;
  }

  return Color(
    int.parse(
      'FF${normalized.substring(1)}',
      radix: 16,
    ),
  );
}
