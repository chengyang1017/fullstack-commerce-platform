import 'package:flutter/material.dart';

import '../repositories/payment_repository.dart';
import '../services/payment_service.dart';

enum PaymentProcessStatus { idle, processing, submitted, cancelled, error }

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;

  PaymentProvider(this._repository);

  PaymentProcessStatus _status = PaymentProcessStatus.idle;

  String? _errorMessage;

  PaymentProcessStatus get status => _status;

  String? get errorMessage => _errorMessage;

  bool get isProcessing {
    return _status == PaymentProcessStatus.processing;
  }

  Future<bool> pay({required String orderId}) async {
    if (isProcessing) {
      return false;
    }

    _status = PaymentProcessStatus.processing;

    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.pay(orderId: orderId);

      /*
       * 不是 success。
       * 只是付款已提交，等待 webhook。
       */
      _status = PaymentProcessStatus.submitted;

      notifyListeners();

      return true;
    } on PaymentCancelledException {
      _status = PaymentProcessStatus.cancelled;

      notifyListeners();

      return false;
    } catch (error) {
      _status = PaymentProcessStatus.error;

      _errorMessage = error.toString();

      notifyListeners();

      return false;
    }
  }
}
