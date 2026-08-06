import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/customer_auth_provider.dart';
import '../providers/order_provider.dart';
import 'orders_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerAuthProvider>().user;

    final orderCount = context.select((OrderProvider provider) {
      return provider.orders.length;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          _AccountHeader(
            name: customer?.name ?? '未知用戶',
            email: customer?.email ?? '',
          ),
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登入'),
            onTap: () async {
              await context.read<CustomerAuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final String name;
  final String email;

  const _AccountHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            child: name.isEmpty
                ? const Icon(Icons.person, size: 36)
                : Text(
                    name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
