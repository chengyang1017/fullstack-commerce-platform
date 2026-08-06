import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../repositories/order_repository.dart';
import 'customer_auth_provider.dart';

enum OrderLoadStatus { initial, loading, ready, error }

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository;
  final CustomerAuthProvider _authProvider;

  OrderProvider(
    this._repository,
    this._authProvider,
  );

  List<Order> _orders = const [];

  final Set<String> _cancellingOrderIds = <String>{};

  OrderLoadStatus _status = OrderLoadStatus.initial;

  String? _errorMessage;

  bool _started = false;
  bool _disposed = false;
  int _loadVersion = 0;
  String? _boundAccountEmail;

  UnmodifiableListView<Order> get orders {
    return UnmodifiableListView(_orders);
  }

  OrderLoadStatus get status => _status;

  String? get errorMessage => _errorMessage;

  bool get isLoading {
    return _status == OrderLoadStatus.loading;
  }

  bool isCancellingOrder(String orderId) {
    return _cancellingOrderIds.contains(orderId);
  }

  void start() {
    if (_started) return;

    _started = true;

    _authProvider.addListener(
      _handleAuthenticationChanged,
    );

    unawaited(_syncAuthentication());
  }

  void _handleAuthenticationChanged() {
    unawaited(_syncAuthentication());
  }

  Future<void> _syncAuthentication() async {
    if (_disposed) return;

    if (_authProvider.status == CustomerAuthStatus.checking) {
      if (_status == OrderLoadStatus.initial) {
        _status = OrderLoadStatus.loading;
        _errorMessage = null;
        notifyListeners();
      }

      return;
    }

    final user = _authProvider.user;

    if (!_authProvider.isLoggedIn || user == null) {
      _loadVersion++;
      _boundAccountEmail = null;
      _orders = const [];
      _cancellingOrderIds.clear();
      _status = OrderLoadStatus.ready;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    if (_boundAccountEmail == user.email &&
        (_status == OrderLoadStatus.loading ||
            _status == OrderLoadStatus.ready)) {
      return;
    }

    _boundAccountEmail = user.email;

    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    final currentVersion = ++_loadVersion;

    _status = OrderLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final orders = await _repository.loadOrders();

      if (_disposed || currentVersion != _loadVersion) {
        return;
      }

      _orders = List<Order>.unmodifiable(orders);
      _status = OrderLoadStatus.ready;
      _errorMessage = null;
    } catch (error) {
      if (_disposed || currentVersion != _loadVersion) {
        return;
      }

      _status = OrderLoadStatus.error;
      _errorMessage = '訂單載入失敗：$error';
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    if (!_authProvider.isLoggedIn || _authProvider.user == null) {
      _orders = const [];
      _status = OrderLoadStatus.ready;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    await _loadOrders();
  }

  void addCreatedOrder(Order order) {
    _replaceOrder(order);
  }

  Future<bool> cancelOrder(String orderId) async {
    if (_disposed || _cancellingOrderIds.contains(orderId)) {
      return false;
    }

    final order = findById(orderId);

    if (order == null) {
      _errorMessage = '找不到這筆訂單';
      notifyListeners();
      return false;
    }

    if (order.status != OrderStatus.pendingPayment) {
      _errorMessage = '只有待付款訂單可以取消';
      notifyListeners();
      return false;
    }

    _cancellingOrderIds.add(orderId);
    _errorMessage = null;
    notifyListeners();

    try {
      final cancelledOrder = await _repository.cancelOrder(orderId);

      if (_disposed) {
        return false;
      }

      _replaceOrder(
        cancelledOrder,
        notify: false,
      );

      _status = OrderLoadStatus.ready;
      _errorMessage = null;

      return true;
    } catch (error) {
      if (_disposed) {
        return false;
      }

      _errorMessage = '取消訂單失敗：$error';
      return false;
    } finally {
      if (!_disposed) {
        _cancellingOrderIds.remove(orderId);
        notifyListeners();
      }
    }
  }

  void _replaceOrder(
    Order order, {
    bool notify = true,
  }) {
    final nextOrders = <Order>[
      order,
      ..._orders.where(
        (existingOrder) => existingOrder.id != order.id,
      ),
    ];

    nextOrders.sort(
      (left, right) => right.createdAt.compareTo(left.createdAt),
    );

    _orders = List<Order>.unmodifiable(nextOrders);
    _status = OrderLoadStatus.ready;
    _errorMessage = null;

    if (notify) {
      notifyListeners();
    }
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
    _disposed = true;
    _loadVersion++;

    if (_started) {
      _authProvider.removeListener(
        _handleAuthenticationChanged,
      );
    }

    super.dispose();
  }
}
