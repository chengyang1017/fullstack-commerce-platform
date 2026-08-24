import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/cart_item.dart';
import '../../models/product.dart';
import '../../repositories/cart_repository.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit({
    required CartRepository repository,
  })  : _repository = repository,
        super(const CartState());

  final CartRepository _repository;

  Future<void>? _loadFuture;

  // 保證購物車操作依序執行，
  // 避免快速點擊造成資料覆蓋。
  Future<void> _operationQueue =
      Future<void>.value();

  Future<void> loadCart({
    bool force = false,
  }) {
    if (force) {
      _loadFuture = null;
    }

    return _loadFuture ??= _loadCart();
  }

  Future<void> _loadCart() async {
    emit(
      CartState(
        status: CartStatus.loading,
        items: state.items,
      ),
    );

    try {
      final items =
          await _repository.loadCart();

      emit(
        CartState(
          status: CartStatus.ready,
          items: List.unmodifiable(items),
        ),
      );
    } catch (error) {
      emit(
        CartState(
          status: CartStatus.error,
          errorMessage:
              '無法載入購物車：$error',
        ),
      );
    }
  }

  Future<void> addProduct(
    Product product,
  ) {
    return _enqueue(() async {
      await loadCart();

      final index =
          _findProductIndex(product.id);

      final nextItems =
          List<CartItem>.from(state.items);

      if (index == -1) {
        nextItems.add(
          CartItem(
            product: product,
            quantity: 1,
          ),
        );
      } else {
        final currentItem =
            nextItems[index];

        nextItems[index] =
            currentItem.copyWith(
          quantity:
              currentItem.quantity + 1,
        );
      }

      await _saveOptimistically(
        nextItems,
      );
    });
  }

  Future<void> increaseQuantity(
    String productId,
  ) {
    return _enqueue(() async {
      await loadCart();

      final index =
          _findProductIndex(productId);

      if (index == -1) {
        return;
      }

      final nextItems =
          List<CartItem>.from(state.items);

      final currentItem =
          nextItems[index];

      nextItems[index] =
          currentItem.copyWith(
        quantity:
            currentItem.quantity + 1,
      );

      await _saveOptimistically(
        nextItems,
      );
    });
  }

  Future<void> decreaseQuantity(
    String productId,
  ) {
    return _enqueue(() async {
      await loadCart();

      final index =
          _findProductIndex(productId);

      if (index == -1) {
        return;
      }

      final nextItems =
          List<CartItem>.from(state.items);

      final currentItem =
          nextItems[index];

      if (currentItem.quantity <= 1) {
        nextItems.removeAt(index);
      } else {
        nextItems[index] =
            currentItem.copyWith(
          quantity:
              currentItem.quantity - 1,
        );
      }

      await _saveOptimistically(
        nextItems,
      );
    });
  }

  Future<void> removeProduct(
    String productId,
  ) {
    return _enqueue(() async {
      await loadCart();

      final nextItems = state.items
          .where(
            (item) =>
                item.product.id !=
                productId,
          )
          .toList(growable: false);

      await _saveOptimistically(
        nextItems,
      );
    });
  }

  Future<void> removePurchasedItems(
    Iterable<CartItem> purchasedItems,
  ) {
    return _enqueue(() async {
      await loadCart();

      final purchasedQuantities =
          <String, int>{};

      for (final item in purchasedItems) {
        purchasedQuantities.update(
          item.product.id,
          (quantity) =>
              quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }

      final nextItems = <CartItem>[];

      for (final currentItem
          in state.items) {
        final purchasedQuantity =
            purchasedQuantities[
                    currentItem.product.id] ??
                0;

        if (purchasedQuantity <= 0) {
          nextItems.add(currentItem);
          continue;
        }

        final remainingQuantity =
            currentItem.quantity -
                purchasedQuantity;

        if (remainingQuantity > 0) {
          nextItems.add(
            currentItem.copyWith(
              quantity:
                  remainingQuantity,
            ),
          );
        }
      }

      await _saveOptimistically(
        nextItems,
      );
    });
  }

  Future<void> clearCart() {
    return _enqueue(() async {
      await loadCart();

      final previousItems =
          state.items;

      emit(
        const CartState(
          status: CartStatus.ready,
          items: [],
        ),
      );

      try {
        await _repository.clearCart();
      } catch (error) {
        emit(
          CartState(
            status: CartStatus.error,
            items: previousItems,
            errorMessage:
                '清空購物車失敗：$error',
          ),
        );

        rethrow;
      }
    });
  }

  Future<void> _saveOptimistically(
    List<CartItem> nextItems,
  ) async {
    final previousItems =
        state.items;

    // 先更新 UI。
    emit(
      CartState(
        status: CartStatus.ready,
        items:
            List.unmodifiable(nextItems),
      ),
    );

    try {
      await _repository.saveCart(
        state.items,
      );
    } catch (error) {
      // 儲存失敗 -> 回滾。
      emit(
        CartState(
          status: CartStatus.error,
          items: previousItems,
          errorMessage:
              '購物車更新失敗：$error',
        ),
      );

      rethrow;
    }
  }

  Future<void> _enqueue(
  Future<void> Function() operation,
) {
  final completer =
      Completer<void>();

  _operationQueue =
      _operationQueue.then(
    (_) async {
      try {
        await operation();
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(
          error,
          stackTrace,
        );
      }
    },
  );

  return completer.future;
}

  int _findProductIndex(
    String productId,
  ) {
    return state.items.indexWhere(
      (item) =>
          item.product.id == productId,
    );
  }
}