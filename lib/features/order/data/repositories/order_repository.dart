import '../../domain/models/order.dart';
import '../services/order_service.dart';

class OrderRepository {
  final OrderService _service;

  const OrderRepository(this._service);

  Future<List<Order>> loadOrders() {
    return _service.loadOrders();
  }

  Future<Order> createOrder(Order order) {
    return _service.createOrder(order);
  }

  Future<Order> cancelOrder(String orderId) {
    return _service.cancelOrder(orderId);
  }

  void dispose() {
    _service.dispose();
  }
}
