import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/payment_provider.dart';
import '../repositories/payment_repository.dart';

class PaymentFlowPage extends StatelessWidget {
  final Order order;

  const PaymentFlowPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return PaymentProvider(context.read<PaymentRepository>());
      },
      child: PaymentPage(order: order),
    );
  }
}

class PaymentPage extends StatefulWidget {
  final Order order;

  const PaymentPage({super.key, required this.order});

  @override
  State<PaymentPage> createState() {
    return _PaymentPageState();
  }
}

class _PaymentPageState extends State<PaymentPage> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final payment = context.watch<PaymentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('訂單付款')),
      body: _buildBody(order, payment),
      bottomNavigationBar: _buildBottomBar(order, payment),
    );
  }

  Widget _buildBody(Order order, PaymentProvider payment) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('應付金額', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  'RM ${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.red,
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
                title: const Text('訂單編號'),
                subtitle: Text(order.displayNumber),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.payment_outlined),
                title: const Text('付款方式'),
                subtitle: Text(order.paymentMethod.title),
              ),
            ],
          ),
        ),
        if (payment.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              payment.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          '付款完成後會自動確認並更新訂單，不需要再次點擊付款。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Order order, PaymentProvider payment) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: payment.isProcessing
              ? null
              : () {
                  _pay(order);
                },
          child: payment.isProcessing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('確認付款 RM ${order.total.toStringAsFixed(2)}'),
        ),
      ),
    );
  }

  Future<void> _pay(Order order) async {
    if (order.status != OrderStatus.pendingPayment) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('這筆訂單目前不需要付款')));

      return;
    }

    final submitted = await context.read<PaymentProvider>().pay(
      orderId: order.id,
    );

    if (!mounted || !submitted) {
      return;
    }

    final orderProvider = context.read<OrderProvider>();
    await orderProvider.refresh();

    if (!mounted) return;

    final latestOrder = orderProvider.findById(order.id);
    final isPaid = latestOrder?.status == OrderStatus.paid;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPaid ? '付款成功，訂單已更新' : '付款已提交，系統會自動更新訂單狀態',
        ),
      ),
    );

    Navigator.pop(context, true);
  }
}
