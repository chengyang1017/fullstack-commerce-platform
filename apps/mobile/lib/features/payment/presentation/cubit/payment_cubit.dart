import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/payment_repository.dart';
import '../../data/services/payment_service.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  PaymentCubit({required PaymentRepository repository})
    : _repository = repository,
      super(const PaymentState());

  final PaymentRepository _repository;

  Future<bool> pay({required String orderId}) async {
    if (state.isProcessing) {
      return false;
    }

    emit(const PaymentState(status: PaymentProcessStatus.processing));

    try {
      await _repository.pay(orderId: orderId);

      /*
       * 这里只代表付款流程已提交。
       *
       * 最終支付結果仍然由 webhook /
       * payment-sync 更新後端訂單狀態。
       */
      emit(const PaymentState(status: PaymentProcessStatus.submitted));

      return true;
    } on PaymentCancelledException {
      emit(const PaymentState(status: PaymentProcessStatus.cancelled));

      return false;
    } on PaymentFailedException catch (error, stackTrace) {
      developer.log(
        'Payment failed',
        name: 'PaymentCubit',
        error: error,
        stackTrace: stackTrace,
      );

      emit(
        PaymentState(
          status: PaymentProcessStatus.error,
          errorType: _mapFailureType(error.type),
        ),
      );

      return false;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected payment failure',
        name: 'PaymentCubit',
        error: error,
        stackTrace: stackTrace,
      );

      emit(
        const PaymentState(
          status: PaymentProcessStatus.error,
          errorType: PaymentErrorType.unknown,
        ),
      );

      return false;
    }
  }

  PaymentErrorType _mapFailureType(PaymentFailureType type) {
    return switch (type) {
      PaymentFailureType.missingCredential =>
        PaymentErrorType.missingCredential,

      PaymentFailureType.paymentFailed => PaymentErrorType.paymentFailed,

      PaymentFailureType.connectionFailed => PaymentErrorType.connectionFailed,

      PaymentFailureType.authenticationExpired =>
        PaymentErrorType.authenticationExpired,

      PaymentFailureType.invalidResponse => PaymentErrorType.invalidResponse,

      PaymentFailureType.createPaymentFailed =>
        PaymentErrorType.createPaymentFailed,

      PaymentFailureType.confirmationFailed =>
        PaymentErrorType.confirmationFailed,
    };
  }
}
