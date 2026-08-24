import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/payment_repository.dart';
import '../../services/payment_service.dart';
import 'payment_state.dart';

class PaymentCubit
    extends Cubit<PaymentState> {
  PaymentCubit({
    required PaymentRepository repository,
  })  : _repository = repository,
        super(const PaymentState());

  final PaymentRepository _repository;

  Future<bool> pay({
    required String orderId,
  }) async {
    if (state.isProcessing) {
      return false;
    }

    emit(
      const PaymentState(
        status:
            PaymentProcessStatus.processing,
      ),
    );

    try {
      await _repository.pay(
        orderId: orderId,
      );

      // 这里只代表付款流程已提交。
      // 最终支付结果仍然由 webhook
      // 更新后端订单状态。
      emit(
        const PaymentState(
          status:
              PaymentProcessStatus.submitted,
        ),
      );

      return true;
    } on PaymentCancelledException {
      emit(
        const PaymentState(
          status:
              PaymentProcessStatus.cancelled,
        ),
      );

      return false;
    } catch (error) {
      emit(
        PaymentState(
          status:
              PaymentProcessStatus.error,
          errorMessage:
              error.toString(),
        ),
      );

      return false;
    }
  }
}