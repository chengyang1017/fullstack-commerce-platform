import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import 'orders_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orderCount = context.select((OrderProvider provider) {
      return provider.orders.length;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const _AccountHeader(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('我的訂單'),
            subtitle: Text(orderCount == 0 ? '查看訂單記錄' : '共有 $orderCount 筆訂單'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const OrdersPage();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(radius: 34, child: Icon(Icons.person, size: 36)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '訪客用戶',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('登入後可同步跨裝置訂單', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
