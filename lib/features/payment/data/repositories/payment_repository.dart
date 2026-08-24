import '../services/payment_service.dart';

class PaymentRepository {
  final PaymentService _service;

  const PaymentRepository(this._service);

  Future<void> pay({required String orderId}) {
    return _service.pay(orderId: orderId);
  }
}
