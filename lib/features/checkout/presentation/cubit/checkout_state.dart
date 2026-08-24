import '../../../address/domain/models/address.dart';
import '../../../order/domain/models/order.dart';

enum CheckoutStatus { initial, loading, ready, submitting, success, error }

enum CheckoutErrorType {
  loadFailed,
  emptyItems,
  addressRequired,
  createOrderFailed,
}

class CheckoutState {
  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.addresses = const [],
    this.selectedAddressId,
    this.shippingMethod = ShippingMethod.standard,
    this.paymentMethod = PaymentMethod.onlineBanking,
    this.errorType,
    this.createdOrder,
    this.cartClearFailed = false,
  });

  final CheckoutStatus status;

  final List<Address> addresses;
  final String? selectedAddressId;

  final ShippingMethod shippingMethod;
  final PaymentMethod paymentMethod;

  final CheckoutErrorType? errorType;

  final Order? createdOrder;

  final bool cartClearFailed;

  bool get isLoading {
    return status == CheckoutStatus.loading;
  }

  bool get isSubmitting {
    return status == CheckoutStatus.submitting;
  }

  Address? get selectedAddress {
    final id = selectedAddressId;

    if (id == null) {
      return null;
    }

    for (final address in addresses) {
      if (address.id == id) {
        return address;
      }
    }

    return null;
  }

  double get shippingFee {
    return shippingMethod.fee;
  }

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<Address>? addresses,
    String? selectedAddressId,
    bool clearSelectedAddress = false,
    ShippingMethod? shippingMethod,
    PaymentMethod? paymentMethod,
    CheckoutErrorType? errorType,
    bool clearError = false,
    Order? createdOrder,
    bool clearCreatedOrder = false,
    bool? cartClearFailed,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      selectedAddressId: clearSelectedAddress
          ? null
          : selectedAddressId ?? this.selectedAddressId,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      errorType: clearError ? null : errorType ?? this.errorType,
      createdOrder: clearCreatedOrder
          ? null
          : createdOrder ?? this.createdOrder,
      cartClearFailed: cartClearFailed ?? this.cartClearFailed,
    );
  }
}
