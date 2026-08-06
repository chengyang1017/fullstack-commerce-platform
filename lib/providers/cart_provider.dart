import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../repositories/cart_repository.dart';

enum CartStatus { initial, loading, ready, error }

class CartProvider extends ChangeNotifier {
  final CartRepository _repository;

  CartProvider({required CartRepository repository})
      : _repository = repository;

  List<CartItem> _items = const [];
  CartStatus _status = CartStatus.initial;
  String? _errorMessage;

  Future<void>? _loadFuture;

  // 保證購物車操作依序執行，避免快速點擊造成資料覆蓋。
  Future<void> _operationQueue = Future<void>.value();

  UnmodifiableListView<CartItem> get items {
    return UnmodifiableListView(_items);
  }

  CartStatus get status => _status;

  String? get errorMessage => _errorMessage;

  bool get isLoading {
    return _status == CartStatus.loading;
  }

  bool get isEmpty => _items.isEmpty;

  int get productTypeCount => _items.length;

  int get totalQuantity {
    return _items.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );
  }

  double get totalPrice {
    return _items.fold<double>(
      0,
      (total, item) => total + item.subtotal,
    );
  }

  int quantityOf(String productId) {
    final index = _findProductIndex(productId);

    if (index == -1) {
      return 0;
    }

    return _items[index].quantity;
  }

  bool containsProduct(String productId) {
    return _findProductIndex(productId) != -1;
  }

  Future<void> loadCart({bool force = false}) {
    if (force) {
      _loadFuture = null;
    }

    return _loadFuture ??= _loadCart();
  }

  Future<void> _loadCart() async {
    _status = CartStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _repository.loadCart();
      _status = CartStatus.ready;
    } catch (error) {
      _items = const [];
      _status = CartStatus.error;
      _errorMessage = '無法載入購物車：$error';
    }

    notifyListeners();
  }

  Future<void> addProduct(Product product) {
    return _enqueue(() async {
      await loadCart();

      final index = _findProductIndex(product.id);
      final nextItems = List<CartItem>.from(_items);

      if (index == -1) {
        nextItems.add(
          CartItem(
            product: product,
            quantity: 1,
          ),
        );
      } else {
        final currentItem = nextItems[index];

        nextItems[index] = currentItem.copyWith(
          quantity: currentItem.quantity + 1,
        );
      }

      await _saveOptimistically(nextItems);
    });
  }

  Future<void> increaseQuantity(String productId) {
    return _enqueue(() async {
      await loadCart();

      final index = _findProductIndex(productId);

      if (index == -1) {
        return;
      }

      final nextItems = List<CartItem>.from(_items);
      final currentItem = nextItems[index];

      nextItems[index] = currentItem.copyWith(
        quantity: currentItem.quantity + 1,
      );

      await _saveOptimistically(nextItems);
    });
  }

  Future<void> decreaseQuantity(String productId) {
    return _enqueue(() async {
      await loadCart();

      final index = _findProductIndex(productId);

      if (index == -1) {
        return;
      }

      final nextItems = List<CartItem>.from(_items);
      final currentItem = nextItems[index];

      if (currentItem.quantity <= 1) {
        nextItems.removeAt(index);
      } else {
        nextItems[index] = currentItem.copyWith(
          quantity: currentItem.quantity - 1,
        );
      }

      await _saveOptimistically(nextItems);
    });
  }

  Future<void> removeProduct(String productId) {
    return _enqueue(() async {
      await loadCart();

      final nextItems = _items
          .where((item) => item.product.id != productId)
          .toList(growable: false);

      await _saveOptimistically(nextItems);
    });
  }

  Future<void> removePurchasedItems(
    Iterable<CartItem> purchasedItems,
  ) {
    return _enqueue(() async {
      await loadCart();

      final purchasedQuantities = <String, int>{};

      for (final item in purchasedItems) {
        purchasedQuantities.update(
          item.product.id,
          (quantity) => quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }

      final nextItems = <CartItem>[];

      for (final currentItem in _items) {
        final purchasedQuantity =
            purchasedQuantities[currentItem.product.id] ?? 0;

        if (purchasedQuantity <= 0) {
          nextItems.add(currentItem);
          continue;
        }

        final remainingQuantity =
            currentItem.quantity - purchasedQuantity;

        if (remainingQuantity > 0) {
          nextItems.add(
            currentItem.copyWith(
              quantity: remainingQuantity,
            ),
          );
        }
      }

      await _saveOptimistically(nextItems);
    });
  }

  Future<void> clearCart() {
    return _enqueue(() async {
      await loadCart();

      final previousItems = _items;

      _items = const [];
      _errorMessage = null;
      _status = CartStatus.ready;
      notifyListeners();

      try {
        await _repository.clearCart();
      } catch (error) {
        _items = previousItems;
        _status = CartStatus.error;
        _errorMessage = '清空購物車失敗：$error';
        notifyListeners();

        rethrow;
      }
    });
  }

  Future<void> _saveOptimistically(
    List<CartItem> nextItems,
  ) async {
    final previousItems = _items;

    // 先更新畫面，使用者不需要等待磁碟或網路。
    _items = List<CartItem>.unmodifiable(nextItems);
    _status = CartStatus.ready;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveCart(_items);
    } catch (error) {
      // 儲存失敗時回滾。
      _items = previousItems;
      _status = CartStatus.error;
      _errorMessage = '購物車更新失敗：$error';
      notifyListeners();

      rethrow;
    }
  }

  Future<void> _enqueue(
    Future<void> Function() operation,
  ) {
    final completer = Completer<void>();

    _operationQueue = _operationQueue.then((_) async {
      try {
        await operation();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  int _findProductIndex(String productId) {
    return _items.indexWhere(
      (item) => item.product.id == productId,
    );
  }
}
