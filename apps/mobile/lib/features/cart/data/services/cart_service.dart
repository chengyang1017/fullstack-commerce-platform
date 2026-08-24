import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/cart_item.dart';

abstract class CartService {
  Future<List<CartItem>> loadItems();

  Future<void> saveItems(List<CartItem> items);

  Future<void> clear();
}

class LocalCartService implements CartService {
  static const String _cartKey = 'shopping_cart_items_v1';

  final SharedPreferencesAsync _preferences;

  LocalCartService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<List<CartItem>> loadItems() async {
    final rawData = await _preferences.getString(_cartKey);

    if (rawData == null || rawData.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(rawData);

      if (decoded is! List) {
        return const [];
      }

      return decoded
          .map(
            (item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } catch (_) {
      // 本地資料損壞時清除，避免 App 一直報錯。
      await _preferences.remove(_cartKey);

      return const [];
    }
  }

  @override
  Future<void> saveItems(List<CartItem> items) async {
    final encoded = jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );

    await _preferences.setString(_cartKey, encoded);
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_cartKey);
  }
}
