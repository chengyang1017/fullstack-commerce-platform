enum PaymentProcessStatus {
  idle,
  processing,
  submitted,
  cancelled,
  error,
}

class PaymentState {
  const PaymentState({
    this.status = PaymentProcessStatus.idle,
    this.errorMessage,
  });

  final PaymentProcessStatus status;
  final String? errorMessage;

  bool get isProcessing {
    return status ==
        PaymentProcessStatus.processing;
  }
}