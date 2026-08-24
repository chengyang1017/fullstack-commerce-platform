import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/order/order_cubit.dart';
import '../cubits/payment/payment_cubit.dart';
import '../cubits/payment/payment_state.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../repositories/payment_repository.dart';

class PaymentFlowPage extends StatelessWidget {
  const PaymentFlowPage({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final paymentRepository = context.read<PaymentRepository>();

    return BlocProvider<PaymentCubit>(
      create: (_) {
        return PaymentCubit(repository: paymentRepository);
      },
      child: PaymentPage(order: order),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.order});

  final Order order;

  @override
  State<PaymentPage> createState() {
    return _PaymentPageState();
  }
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    final l10n = AppLocalizations.of(context);

    return BlocBuilder<PaymentCubit, PaymentState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.orderPayment)),
          body: _buildBody(order, state),
          bottomNavigationBar: _buildBottomBar(order, state),
        );
      },
    );
  }

  Widget _buildBody(Order order, PaymentState state) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  l10n.amountDue,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),

                const SizedBox(height: 10),

                Text(
                  'RM ${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(l10n.orderNumberLabel),
                subtitle: Text(order.displayNumber),
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(Icons.payment_outlined),
                title: Text(l10n.paymentMethod),
                subtitle: Text(_paymentMethodTitle(l10n, order.paymentMethod)),
              ),
            ],
          ),
        ),

        if (state.errorType != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _paymentErrorMessage(l10n, state.errorType!),
              style: TextStyle(color: colorScheme.error),
            ),
          ),

        const SizedBox(height: 16),

        Text(
          l10n.paymentAutoUpdateNote,
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Order order, PaymentState state) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: state.isProcessing
              ? null
              : () {
                  _pay(order);
                },
          child: state.isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.confirmPayment(order.total.toStringAsFixed(2))),
        ),
      ),
    );
  }

  Future<void> _pay(Order order) async {
    final l10n = AppLocalizations.of(context);

    if (order.status != OrderStatus.pendingPayment) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.orderDoesNotNeedPayment)));

      return;
    }

    final submitted = await context.read<PaymentCubit>().pay(orderId: order.id);

    if (!mounted || !submitted) {
      return;
    }

    final orderCubit = context.read<OrderCubit>();

    await orderCubit.refresh();

    if (!mounted) {
      return;
    }

    final latestOrder = orderCubit.state.findById(order.id);

    final isPaid = latestOrder?.status == OrderStatus.paid;

    final currentL10n = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPaid
              ? currentL10n.paymentSuccessOrderUpdated
              : currentL10n.paymentSubmittedAutoUpdate,
        ),
      ),
    );

    Navigator.pop(context, true);
  }
}

String _paymentMethodTitle(AppLocalizations l10n, PaymentMethod method) {
  return switch (method) {
    PaymentMethod.onlineBanking => l10n.onlineBanking,

    PaymentMethod.card => l10n.creditDebitCard,

    PaymentMethod.cashOnDelivery => l10n.cashOnDelivery,
  };
}

String _paymentErrorMessage(AppLocalizations l10n, PaymentErrorType type) {
  return switch (type) {
    PaymentErrorType.missingCredential => l10n.paymentCredentialMissing,

    PaymentErrorType.paymentFailed => l10n.paymentFailedTryAnotherMethod,

    PaymentErrorType.connectionFailed => l10n.paymentConnectionFailed,

    PaymentErrorType.authenticationExpired => l10n.paymentSessionExpired,

    PaymentErrorType.invalidResponse => l10n.paymentInvalidResponse,

    PaymentErrorType.createPaymentFailed => l10n.paymentCreationFailed,

    PaymentErrorType.confirmationFailed => l10n.paymentConfirmationFailed,

    PaymentErrorType.unknown => l10n.paymentUnknownError,
  };
}
