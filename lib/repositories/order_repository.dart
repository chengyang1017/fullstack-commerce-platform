import '../models/order.dart';
import '../services/order_service.dart';

class OrderRepository {
  final OrderService _service;

  const OrderRepository(this._service);

  Stream<List<Order>> watchOrders(String userId) {
    return _service.watchOrders(userId);
  }

  Future<void> createOrder(Order order) {
    return _service.createOrder(order);
  }
}
