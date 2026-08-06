import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import 'payment_page.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;

  const OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    final order = provider.findById(orderId);

    return Scaffold(
      appBar: AppBar(title: const Text('訂單詳情')),
      body: _buildBody(context, provider, order),
      bottomNavigationBar: order == null
          ? null
          : _buildBottomBar(
              context,
              provider,
              order,
            ),
    );
  }

  Widget? _buildBottomBar(
    BuildContext context,
    OrderProvider provider,
    Order order,
  ) {
    if (order.status != OrderStatus.pendingPayment) {
      return null;
    }

    final isCancelling = provider.isCancellingOrder(order.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isCancelling
                    ? null
                    : () {
                        _confirmCancellation(
                          context,
                          provider,
                          order,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('取消訂單'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
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
                  '去付款 · RM '
                  '${order.total.toStringAsFixed(2)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancellation(
    BuildContext context,
    OrderProvider provider,
    Order order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('取消訂單'),
          content: const Text(
            '取消後，這筆訂單占用的商品庫存會自動恢復。確定取消嗎？',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('返回'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('確定取消'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final cancelled = await provider.cancelOrder(order.id);

    if (!context.mounted) {
      return;
    }

    final message = cancelled
        ? '訂單已取消，商品庫存已恢復'
        : provider.errorMessage ?? '取消訂單失敗';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _openPayment(
    BuildContext context,
    Order order,
  ) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return PaymentFlowPage(order: order);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrderProvider provider,
    Order? order,
  ) {
    if (order == null && provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (order == null) {
      return _buildMissingOrder(provider);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildStatusSection(order),
        const SizedBox(height: 12),
        _buildAddressSection(order),
        const SizedBox(height: 12),
        _buildProductSection(order),
        const SizedBox(height: 12),
        _buildDeliverySection(order),
        const SizedBox(height: 12),
        _buildPriceSection(order),
        const SizedBox(height: 12),
        _buildOrderInformation(order),
      ],
    );
  }

  Widget _buildStatusSection(Order order) {
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
                  order.status.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusDescription(order.status),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(Order order) {
    final address = order.address;

    return _DetailsSection(
      title: '收貨地址',
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

  Widget _buildProductSection(Order order) {
    return _DetailsSection(
      title: '商品',
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
                      return const SizedBox(
                        width: 76,
                        height: 76,
                        child: ColoredBox(
                          color: Color(0xFFF2F2F2),
                          child: Icon(Icons.broken_image_outlined),
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
                        'RM '
                        '${item.unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.red),
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

  Widget _buildDeliverySection(Order order) {
    return _DetailsSection(
      title: '配送與付款',
      child: Column(
        children: [
          _InformationRow(label: '配送方式', value: order.shippingMethod.title),
          const SizedBox(height: 12),
          _InformationRow(label: '付款方式', value: order.paymentMethod.title),
        ],
      ),
    );
  }

  Widget _buildPriceSection(Order order) {
    return _DetailsSection(
      title: '金額明細',
      child: Column(
        children: [
          _InformationRow(
            label: '商品小計',
            value: 'RM ${order.subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _InformationRow(
            label: '運費',
            value: 'RM ${order.shippingFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _InformationRow(
            label: '優惠',
            value: '- RM ${order.discount.toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
          _InformationRow(
            label: '訂單總額',
            value: 'RM ${order.total.toStringAsFixed(2)}',
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInformation(Order order) {
    return _DetailsSection(
      title: '訂單資訊',
      child: Column(
        children: [
          _InformationRow(
            label: '訂單編號',
            value: order.displayNumber,
          ),
          const SizedBox(height: 12),
          _InformationRow(label: '建立時間', value: _formatDate(order.createdAt)),
        ],
      ),
    );
  }

  Widget _buildMissingOrder(OrderProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('找不到這筆訂單'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                provider.refresh();
              },
              child: const Text('重新載入'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pendingPayment:
        return '請完成付款以繼續處理訂單';
      case OrderStatus.paid:
        return '付款成功，等待商家處理';
      case OrderStatus.processing:
        return '商家正在準備您的商品';
      case OrderStatus.shipped:
        return '商品已交給物流公司';
      case OrderStatus.delivered:
        return '商品已送達，請確認收貨';
      case OrderStatus.completed:
        return '這筆訂單已完成';
      case OrderStatus.cancelled:
        return '這筆訂單已取消';
      case OrderStatus.refunded:
        return '這筆訂單已退款';
    }
  }
}

class _DetailsSection extends StatelessWidget {
  final String? title;
  final Widget child;

  const _DetailsSection({this.title, required this.child});

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
  final String label;
  final String value;
  final bool emphasized;

  const _InformationRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: emphasized ? Colors.red : null,
              fontSize: emphasized ? 18 : null,
              fontWeight: emphasized ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }
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
