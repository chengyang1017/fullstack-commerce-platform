import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../address/domain/models/address.dart';
import '../../domain/models/checkout_request.dart';
import '../../../order/domain/models/order.dart';
import '../../../address/data/repositories/address_repository.dart';
import '../../../order/data/repositories/order_repository.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
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
    } catch (error, stackTrace) {
      developer.log(
        'Failed to initialize checkout',
        name: 'CheckoutCubit',
        error: error,
        stackTrace: stackTrace,
      );

      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          errorType: CheckoutErrorType.loadFailed,
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
      _setError(CheckoutErrorType.emptyItems);

      return null;
    }

    if (address == null) {
      _setError(CheckoutErrorType.addressRequired);

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
        } catch (error, stackTrace) {
          developer.log(
            'Order created but failed to remove purchased cart items',
            name: 'CheckoutCubit',
            error: error,
            stackTrace: stackTrace,
          );

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
    } catch (error, stackTrace) {
      developer.log(
        'Failed to create order',
        name: 'CheckoutCubit',
        error: error,
        stackTrace: stackTrace,
      );

      emit(
        state.copyWith(
          status: CheckoutStatus.error,
          errorType: CheckoutErrorType.createOrderFailed,
        ),
      );

      return null;
    }
  }

  void _setError(CheckoutErrorType type) {
    emit(state.copyWith(status: CheckoutStatus.error, errorType: type));
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
