import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/order.dart';
import '../../../payment/presentation/pages/payment_page.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        final order = state.findById(orderId);

        return Scaffold(
          appBar: AppBar(title: Text(l10n.orderDetails)),
          body: _buildBody(context, state, order),
          bottomNavigationBar: order == null
              ? null
              : _buildBottomBar(context, state, order),
        );
      },
    );
  }

Widget? _buildBottomBar(
  BuildContext context,
  OrderState state,
  Order order,
) {
  if (order.status != OrderStatus.pendingPayment) {
    return null;
  }

  final colorScheme =
      Theme.of(context).colorScheme;

  final l10n =
      AppLocalizations.of(context);

  final isCancelling =
      state.isCancellingOrder(order.id);

  return SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isCancelling
                  ? null
                  : () {
                      _openPayment(
                        context,
                        order,
                      );
                    },
              child: Text(
                l10n.goToPayment(
                  order.total
                      .toStringAsFixed(2),
                ),
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: isCancelling
                  ? null
                  : () {
                      _confirmCancellation(
                        context,
                        order,
                      );
                    },
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    colorScheme.error,
                side: BorderSide(
                  color: colorScheme.error,
                ),
              ),
              child: isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      l10n.cancelOrder,
                      maxLines: 1,
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Future<void> _confirmCancellation(BuildContext context, Order order) async {
    final l10n = AppLocalizations.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.cancelOrder),
          content: Text(l10n.cancelOrderConfirmation),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(l10n.back),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: Text(l10n.confirmCancellation),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final orderCubit = context.read<OrderCubit>();

    final cancelled = await orderCubit.cancelOrder(order.id);

    if (!context.mounted) {
      return;
    }

    final currentL10n = AppLocalizations.of(context);

    final message = cancelled
        ? currentL10n.orderCancelledStockRestored
        : _orderErrorMessage(
            currentL10n,
            orderCubit.state.errorType,
            fallback: currentL10n.cancelOrderFailed,
          );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPayment(BuildContext context, Order order) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return PaymentFlowPage(order: order);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderState state, Order? order) {
    if (order == null && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (order == null) {
      return _buildMissingOrder(context);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildStatusSection(context, order),

        const SizedBox(height: 12),

        _buildAddressSection(context, order),

        const SizedBox(height: 12),

        _buildProductSection(context, order),

        const SizedBox(height: 12),

        _buildDeliverySection(context, order),

        const SizedBox(height: 12),

        _buildPriceSection(context, order),

        const SizedBox(height: 12),

        _buildOrderInformation(context, order),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    return _DetailsSection(
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 42),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _orderStatusTitle(l10n, order.status),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _statusDescription(l10n, order.status),
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);

    final address = order.address;

    return _DetailsSection(
      title: l10n.shippingAddress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${address.receiverName}  '
                  '${address.phone}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 6),

                Text(address.fullAddress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    return _DetailsSection(
      title: l10n.products,
      child: Column(
        children: order.items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.productImage,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return SizedBox(
                        width: 76,
                        height: 76,
                        child: ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'RM ${item.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),

                Text('× ${item.quantity}'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliverySection(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);

    return _DetailsSection(
      title: l10n.deliveryAndPayment,
      child: Column(
        children: [
          _InformationRow(
            label: l10n.shippingMethod,
            value: _shippingMethodTitle(l10n, order.shippingMethod),
          ),

          const SizedBox(height: 12),

          _InformationRow(
            label: l10n.paymentMethod,
            value: _paymentMethodTitle(l10n, order.paymentMethod),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);

    return _DetailsSection(
      title: l10n.amountDetails,
      child: Column(
        children: [
          _InformationRow(
            label: l10n.productSubtotal,
            value: 'RM ${order.subtotal.toStringAsFixed(2)}',
          ),

          const SizedBox(height: 10),

          _InformationRow(
            label: l10n.shippingFee,
            value: 'RM ${order.shippingFee.toStringAsFixed(2)}',
          ),

          const SizedBox(height: 10),

          _InformationRow(
            label: l10n.discount,
            value: '- RM ${order.discount.toStringAsFixed(2)}',
          ),

          const Divider(height: 24),

          _InformationRow(
            label: l10n.orderGrandTotal,
            value: 'RM ${order.total.toStringAsFixed(2)}',
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInformation(BuildContext context, Order order) {
    final l10n = AppLocalizations.of(context);

    return _DetailsSection(
      title: l10n.orderInformation,
      child: Column(
        children: [
          _InformationRow(
            label: l10n.orderNumberLabel,
            value: order.displayNumber,
          ),

          const SizedBox(height: 12),

          _InformationRow(
            label: l10n.createdAt,
            value: _formatDate(order.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingOrder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 16),

            Text(l10n.orderNotFound),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: () {
                context.read<OrderCubit>().refresh();
              },
              child: Text(l10n.reload),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),
            ],

            child,
          ],
        ),
      ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: emphasized ? colorScheme.primary : null,
              fontSize: emphasized ? 18 : null,
              fontWeight: emphasized ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }
}

String _orderStatusTitle(AppLocalizations l10n, OrderStatus status) {
  return switch (status) {
    OrderStatus.pendingPayment => l10n.pendingPayment,

    OrderStatus.paid => l10n.orderStatusPaid,

    OrderStatus.processing => l10n.processing,

    OrderStatus.shipped => l10n.orderStatusShipped,

    OrderStatus.delivered => l10n.orderStatusDelivered,

    OrderStatus.completed => l10n.completed,

    OrderStatus.cancelled => l10n.cancelled,

    OrderStatus.refunded => l10n.orderStatusRefunded,
  };
}

String _statusDescription(AppLocalizations l10n, OrderStatus status) {
  return switch (status) {
    OrderStatus.pendingPayment => l10n.statusPendingPaymentDescription,

    OrderStatus.paid => l10n.statusPaidDescription,

    OrderStatus.processing => l10n.statusProcessingDescription,

    OrderStatus.shipped => l10n.statusShippedDescription,

    OrderStatus.delivered => l10n.statusDeliveredDescription,

    OrderStatus.completed => l10n.statusCompletedDescription,

    OrderStatus.cancelled => l10n.statusCancelledDescription,

    OrderStatus.refunded => l10n.statusRefundedDescription,
  };
}

String _shippingMethodTitle(AppLocalizations l10n, ShippingMethod method) {
  return switch (method) {
    ShippingMethod.standard => l10n.standardShipping,

    ShippingMethod.express => l10n.expressShipping,
  };
}

String _paymentMethodTitle(AppLocalizations l10n, PaymentMethod method) {
  return switch (method) {
    PaymentMethod.onlineBanking => l10n.onlineBanking,

    PaymentMethod.card => l10n.creditDebitCard,

    PaymentMethod.cashOnDelivery => l10n.cashOnDelivery,
  };
}

String _orderErrorMessage(
  AppLocalizations l10n,
  OrderErrorType? type, {
  required String fallback,
}) {
  return switch (type) {
    OrderErrorType.loadFailed => l10n.orderLoadFailed,

    OrderErrorType.notFound => l10n.orderNotFound,

    OrderErrorType.cancellationNotAllowed =>
      l10n.onlyPendingPaymentCanBeCancelled,

    OrderErrorType.cancelFailed => l10n.cancelOrderFailed,

    null => fallback,
  };
}

String _formatDate(DateTime dateTime) {
  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  return '${dateTime.year}-'
      '${twoDigits(dateTime.month)}-'
      '${twoDigits(dateTime.day)} '
      '${twoDigits(dateTime.hour)}:'
      '${twoDigits(dateTime.minute)}';
}
