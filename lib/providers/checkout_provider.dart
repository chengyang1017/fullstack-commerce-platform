import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/address.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../repositories/address_repository.dart';
import '../repositories/order_repository.dart';

enum CheckoutStatus { initial, loading, ready, submitting, success, error }

class CheckoutProvider extends ChangeNotifier {
  final AddressRepository _addressRepository;

  final OrderRepository _orderRepository;

  CheckoutProvider({
    required AddressRepository addressRepository,
    required OrderRepository orderRepository,
  }) : _addressRepository = addressRepository,
       _orderRepository = orderRepository;

  List<Address> _addresses = const [];

  String? _selectedAddressId;

  ShippingMethod _shippingMethod = ShippingMethod.standard;

  PaymentMethod _paymentMethod = PaymentMethod.onlineBanking;

  CheckoutStatus _status = CheckoutStatus.initial;

  String? _errorMessage;
  Order? _createdOrder;
  bool _cartClearFailed = false;

  UnmodifiableListView<Address> get addresses {
    return UnmodifiableListView(_addresses);
  }

  CheckoutStatus get status => _status;

  String? get errorMessage => _errorMessage;

  ShippingMethod get shippingMethod {
    return _shippingMethod;
  }

  PaymentMethod get paymentMethod {
    return _paymentMethod;
  }

  Order? get createdOrder => _createdOrder;

  bool get cartClearFailed => _cartClearFailed;

  bool get isLoading {
    return _status == CheckoutStatus.loading;
  }

  bool get isSubmitting {
    return _status == CheckoutStatus.submitting;
  }

  Address? get selectedAddress {
    if (_selectedAddressId == null) {
      return null;
    }

    for (final address in _addresses) {
      if (address.id == _selectedAddressId) {
        return address;
      }
    }

    return null;
  }

  double get shippingFee {
    return _shippingMethod.fee;
  }

  double total(CartProvider cart) {
    return cart.totalPrice + shippingFee;
  }

  Future<void> initialize() async {
    _status = CheckoutStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _addresses = await _addressRepository.loadAddresses();

      _selectInitialAddress();

      _status = CheckoutStatus.ready;
    } catch (error) {
      _status = CheckoutStatus.error;
      _errorMessage = '無法載入結算資料：$error';
    }

    notifyListeners();
  }

  Future<void> addAddress(Address address) async {
    final isFirstAddress = _addresses.isEmpty;

    var nextAddress = address.copyWith(
      isDefault: isFirstAddress || address.isDefault,
    );

    var nextAddresses = List<Address>.from(_addresses);

    if (nextAddress.isDefault) {
      nextAddresses = nextAddresses.map((item) {
        return item.copyWith(isDefault: false);
      }).toList();
    }

    nextAddresses.add(nextAddress);

    await _addressRepository.saveAddresses(nextAddresses);

    _addresses = List.unmodifiable(nextAddresses);

    _selectedAddressId = nextAddress.id;

    notifyListeners();
  }

  void selectAddress(String addressId) {
    _selectedAddressId = addressId;
    notifyListeners();
  }

  void selectShippingMethod(ShippingMethod method) {
    _shippingMethod = method;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<Order?> placeOrder({
    required CartProvider cart,
    required String userId,
  }) async {
    final address = selectedAddress;

    if (userId.trim().isEmpty) {
        _setError('登入資料異常，缺少 userId');
        return null;
      }
    if (cart.isEmpty) {
      _setError('購物車沒有商品');
      return null;
    }

    if (address == null) {
      _setError('請先選擇收貨地址');
      return null;
    }

    _status = CheckoutStatus.submitting;
    _errorMessage = null;
    _cartClearFailed = false;
    notifyListeners();

    final now = DateTime.now();

    final orderItems = cart.items
        .map(OrderItem.fromCartItem)
        .toList(growable: false);

    final order = Order(
      id:
          'order_'
          '${now.microsecondsSinceEpoch}',
      userId: userId,
      address: address,
      items: orderItems,
      shippingMethod: _shippingMethod,
      paymentMethod: _paymentMethod,
      status: _paymentMethod == PaymentMethod.cashOnDelivery
          ? OrderStatus.processing
          : OrderStatus.pendingPayment,
      subtotal: cart.totalPrice,
      shippingFee: shippingFee,
      discount: 0,
      total: total(cart),
      createdAt: now,
    );

    try {
      await _orderRepository.createOrder(order);

      _createdOrder = order;

      try {
        await cart.clearCart();
      } catch (_) {
        // 訂單已建立，不能因清空購物車失敗
        // 再次提交訂單。
        _cartClearFailed = true;
      }

      _status = CheckoutStatus.success;
      notifyListeners();

      return order;
    } catch (error) {
      _status = CheckoutStatus.error;
      _errorMessage = '建立訂單失敗：$error';

      notifyListeners();
      return null;
    }
  }

  void _selectInitialAddress() {
    if (_addresses.isEmpty) {
      _selectedAddressId = null;
      return;
    }

    final defaultAddresses = _addresses.where((address) => address.isDefault);

    _selectedAddressId = defaultAddresses.isNotEmpty
        ? defaultAddresses.first.id
        : _addresses.first.id;
  }

  void _setError(String message) {
    _status = CheckoutStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}
