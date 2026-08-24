import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/order/order_cubit.dart';
import '../cubits/order/order_state.dart';
import '../models/order.dart';
import 'order_details_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() {
    return _OrdersPageState();
  }
}

class _OrdersPageState extends State<OrdersPage> {
  static const List<_OrderFilter> _filters = [
    _OrderFilter(title: '全部'),
    _OrderFilter(title: '待付款', statuses: {OrderStatus.pendingPayment}),
    _OrderFilter(
      title: '處理中',
      statuses: {OrderStatus.paid, OrderStatus.processing},
    ),
    _OrderFilter(
      title: '待收貨',
      statuses: {OrderStatus.shipped, OrderStatus.delivered},
    ),
    _OrderFilter(title: '已完成', statuses: {OrderStatus.completed}),
    _OrderFilter(title: '已取消', statuses: {OrderStatus.cancelled}),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _filters.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的訂單'),
          bottom: TabBar(
            isScrollable: true,
            tabs: _filters.map((filter) {
              return Tab(text: filter.title);
            }).toList(),
          ),
        ),
        body: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            return _buildBody(state);
          },
        ),
      ),
    );
  }

  Widget _buildBody(OrderState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == OrderLoadStatus.error && state.orders.isEmpty) {
      return _buildErrorView(state);
    }

    return TabBarView(
      children: _filters.map((filter) {
        final orders = state.orders
            .where(filter.matches)
            .toList(growable: false);

        return _buildOrderList(orders);
      }).toList(),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                '暫時沒有訂單',
                style: TextStyle(color: Colors.grey, fontSize: 17),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          final order = orders[index];

          return _OrderCard(
            order: order,
            onTap: () {
              _openOrderDetails(order.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorView(OrderState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? '訂單載入失敗', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                _refresh();
              },
              child: const Text('重新載入'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() {
    return BlocProvider.of<OrderCubit>(context).refresh();
  }

  Future<void> _openOrderDetails(String orderId) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return OrderDetailsPage(orderId: orderId);
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.first;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '訂單 '
                      '${order.displayNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                  _OrderStatusChip(status: order.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      firstItem.productImage,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          width: 72,
                          height: 72,
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
                          firstItem.productTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.items.length == 1
                              ? '共 '
                                    '${firstItem.quantity} '
                                    '件商品'
                              : '共 '
                                    '${order.items.length} '
                                    '種商品',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Spacer(),
                  const Text('總額：'),
                  Text(
                    'RM '
                    '${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.title),
    );
  }
}

class _OrderFilter {
  final String title;
  final Set<OrderStatus>? statuses;

  const _OrderFilter({required this.title, this.statuses});

  bool matches(Order order) {
    return statuses == null || statuses!.contains(order.status);
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
