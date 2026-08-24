import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/address.dart';
import '../../models/checkout_request.dart';
import '../../models/order.dart';
import '../../repositories/address_repository.dart';
import '../../repositories/order_repository.dart';
import '../cart/cart_cubit.dart';
import 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required AddressRepository addressRepository,
    required OrderRepository orderRepository,
  }) : _addressRepository = addressRepository,
       _orderRepository = orderRepository,
       super(const CheckoutState());

  final AddressRepository _addressRepository;

  final OrderRepository _orderRepository;

  Future<void> initialize() async {
    emit(state.copyWith(status: CheckoutStatus.loading, clearError: true));

    try {
      final addresses = await _addressRepository.loadAddresses();

      final selectedAddressId = _initialAddressId(addresses);

      emit(
        state.copyWith(
          status: CheckoutStatus.ready,
          addresses: List.unmodifiable(addresses),
          selectedAddressId: selectedAddressId,
          clearSelectedAddress: selectedAddressId == null,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          errorMessage: '無法載入結算資料：$error',
        ),
      );
    }
  }

  Future<void> addAddress(Address address) async {
    final isFirstAddress = state.addresses.isEmpty;

    final nextAddress = address.copyWith(
      isDefault: isFirstAddress || address.isDefault,
    );

    var nextAddresses = List<Address>.from(state.addresses);

    if (nextAddress.isDefault) {
      nextAddresses = nextAddresses.map((item) {
        return item.copyWith(isDefault: false);
      }).toList();
    }

    nextAddresses.add(nextAddress);

    await _addressRepository.saveAddresses(nextAddresses);

    emit(
      state.copyWith(
        addresses: List.unmodifiable(nextAddresses),
        selectedAddressId: nextAddress.id,
        clearError: true,
      ),
    );
  }

  void selectAddress(String addressId) {
    emit(state.copyWith(selectedAddressId: addressId));
  }

  void selectShippingMethod(ShippingMethod method) {
    emit(state.copyWith(shippingMethod: method));
  }

  void selectPaymentMethod(PaymentMethod method) {
    emit(state.copyWith(paymentMethod: method));
  }

  double subtotal(CheckoutRequest request) {
    return request.items.fold<double>(
      0,
      (total, item) => total + item.subtotal,
    );
  }

  double total(CheckoutRequest request) {
    return subtotal(request) + state.shippingFee;
  }

  Future<Order?> placeOrder({
    required CheckoutRequest request,
    required CartCubit cart,
  }) async {
    final address = state.selectedAddress;

    if (request.items.isEmpty) {
      _setError('沒有可以結算的商品');

      return null;
    }

    if (address == null) {
      _setError('請先選擇收貨地址');

      return null;
    }

    emit(
      state.copyWith(
        status: CheckoutStatus.submitting,
        clearError: true,
        clearCreatedOrder: true,
        cartClearFailed: false,
      ),
    );

    final now = DateTime.now();

    final orderSubtotal = subtotal(request);

    final draftOrder = Order(
      id: '',
      address: address,
      items: request.items.map(OrderItem.fromCartItem).toList(growable: false),
      shippingMethod: state.shippingMethod,
      paymentMethod: state.paymentMethod,
      status: state.paymentMethod == PaymentMethod.cashOnDelivery
          ? OrderStatus.processing
          : OrderStatus.pendingPayment,
      subtotal: orderSubtotal,
      shippingFee: state.shippingFee,
      discount: 0,
      total: orderSubtotal + state.shippingFee,
      createdAt: now,
    );

    try {
      final createdOrder = await _orderRepository.createOrder(draftOrder);

      var cartClearFailed = false;

      if (request.isFromCart) {
        try {
          await cart.removePurchasedItems(request.items);
        } catch (_) {
          // 訂單已經建立成功，
          // 不能因購物車同步失敗再次提交訂單。
          cartClearFailed = true;
        }
      }

      emit(
        state.copyWith(
          status: CheckoutStatus.success,
          createdOrder: createdOrder,
          cartClearFailed: cartClearFailed,
          clearError: true,
        ),
      );

      return createdOrder;
    } catch (error) {
      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          errorMessage: '建立訂單失敗：$error',
        ),
      );

      return null;
    }
  }

  void _setError(String message) {
    emit(state.copyWith(status: CheckoutStatus.error, errorMessage: message));
  }

  String? _initialAddressId(List<Address> addresses) {
    if (addresses.isEmpty) {
      return null;
    }

    for (final address in addresses) {
      if (address.isDefault) {
        return address.id;
      }
    }

    return addresses.first.id;
  }
}
