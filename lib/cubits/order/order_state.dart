import '../../models/order.dart';

enum OrderLoadStatus { initial, loading, ready, error }

enum OrderErrorType {
  loadFailed,
  notFound,
  cancellationNotAllowed,
  cancelFailed,
}

class OrderState {
  const OrderState({
    this.status = OrderLoadStatus.initial,
    this.orders = const [],
    this.cancellingOrderIds = const {},
    this.errorType,
  });

  final OrderLoadStatus status;

  final List<Order> orders;

  final Set<String> cancellingOrderIds;

  final OrderErrorType? errorType;

  bool get isLoading {
    return status == OrderLoadStatus.loading;
  }

  bool isCancellingOrder(String orderId) {
    return cancellingOrderIds.contains(orderId);
  }

  Order? findById(String orderId) {
    for (final order in orders) {
      if (order.id == orderId) {
        return order;
      }
    }

    return null;
  }

  int countByStatus(OrderStatus status) {
    return orders.where((order) => order.status == status).length;
  }

  OrderState copyWith({
    OrderLoadStatus? status,
    List<Order>? orders,
    Set<String>? cancellingOrderIds,
    OrderErrorType? errorType,
    bool clearError = false,
  }) {
    return OrderState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      cancellingOrderIds: cancellingOrderIds ?? this.cancellingOrderIds,
      errorType: clearError ? null : errorType ?? this.errorType,
    );
  }
}
