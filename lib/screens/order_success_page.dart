import 'package:flutter/material.dart';

import '../models/order.dart';
import 'order_details_page.dart';
import 'orders_page.dart';
import 'payment_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final Order order;
  final bool cartClearFailed;

  const OrderSuccessPage({
    super.key,
    required this.order,
    required this.cartClearFailed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('訂單完成'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 90, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                '訂單已建立',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('訂單編號：${order.id}'),
              const SizedBox(height: 8),
              Text(
                '付款金額：RM '
                '${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (cartClearFailed) ...[
                const SizedBox(height: 12),
                const Text(
                  '訂單已建立，但購物車清理失敗。',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  if (order.status == OrderStatus.pendingPayment) {
                    final paid = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return PaymentFlowPage(order: order);
                        },
                      ),
                    );

                    if (!context.mounted || paid != true) {
                      return;
                    }
                  }

                  if (!context.mounted) return;

                  await Navigator.pushReplacement<void, void>(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return OrderDetailsPage(orderId: order.id);
                      },
                    ),
                  );
                },
                child: Text(
                  order.status == OrderStatus.pendingPayment
                      ? '立即付款'
                      : '查看這筆訂單',
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacement<void, void>(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const OrdersPage();
                      },
                    ),
                  );
                },
                child: const Text('查看全部訂單'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('繼續購物'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
