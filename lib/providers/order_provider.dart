import 'dart:async';
import 'dart:collection';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';

enum OrderLoadStatus { initial, loading, ready, error }

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository;
  final FirebaseAuth _auth;

  OrderProvider(this._repository, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  List<Order> _orders = const [];

  OrderLoadStatus _status = OrderLoadStatus.initial;

  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;

  StreamSubscription<List<Order>>? _ordersSubscription;

  bool _started = false;
  int _bindingVersion = 0;

  UnmodifiableListView<Order> get orders {
    return UnmodifiableListView(_orders);
  }

  OrderLoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  bool get isLoading {
    return _status == OrderLoadStatus.loading;
  }

  void start() {
    if (_started) return;

    _started = true;

    _authSubscription = _auth.authStateChanges().listen(
      (user) {
        unawaited(_bindUser(user));
      },
      onError: (Object error) {
        _status = OrderLoadStatus.error;
        _errorMessage = '登入狀態讀取失敗：$error';

        notifyListeners();
      },
    );
  }

  Future<void> _bindUser(User? user) async {
    final currentVersion = ++_bindingVersion;

    await _ordersSubscription?.cancel();
    _ordersSubscription = null;

    if (currentVersion != _bindingVersion) {
      return;
    }

    if (user == null) {
      _orders = const [];
      _status = OrderLoadStatus.ready;
      _errorMessage = null;

      notifyListeners();
      return;
    }

    _orders = const [];
    _status = OrderLoadStatus.loading;
    _errorMessage = null;

    notifyListeners();

    _ordersSubscription = _repository
        .watchOrders(user.uid)
        .listen(
          (orders) {
            if (currentVersion != _bindingVersion) {
              return;
            }

            _orders = List<Order>.unmodifiable(orders);

            _status = OrderLoadStatus.ready;
            _errorMessage = null;

            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (currentVersion != _bindingVersion) {
              return;
            }

            _status = OrderLoadStatus.error;
            _errorMessage = '訂單監聽失敗：$error';

            notifyListeners();
          },
        );
  }

  Future<void> refresh() {
  return _bindUser(_auth.currentUser);
}
  

  Order? findById(String orderId) {
    for (final order in _orders) {
      if (order.id == orderId) {
        return order;
      }
    }

    return null;
  }

  int countByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).length;
  }

  @override
  void dispose() {
    _bindingVersion++;

    _authSubscription?.cancel();
    _ordersSubscription?.cancel();

    super.dispose();
  }
}
