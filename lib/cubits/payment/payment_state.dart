enum PaymentProcessStatus { idle, processing, submitted, cancelled, error }

enum PaymentErrorType {
  missingCredential,
  paymentFailed,
  connectionFailed,
  authenticationExpired,
  invalidResponse,
  createPaymentFailed,
  confirmationFailed,
  unknown,
}

class PaymentState {
  const PaymentState({this.status = PaymentProcessStatus.idle, this.errorType});

  final PaymentProcessStatus status;

  final PaymentErrorType? errorType;

  bool get isProcessing {
    return status == PaymentProcessStatus.processing;
  }
}
