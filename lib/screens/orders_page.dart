import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/order/order_cubit.dart';
import '../cubits/order/order_state.dart';
import '../l10n/app_localizations.dart';
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final filters = _buildFilters(l10n);

    return DefaultTabController(
      length: filters.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myOrders),
          bottom: TabBar(
            isScrollable: true,
            tabs: filters.map((filter) {
              return Tab(text: filter.title);
            }).toList(),
          ),
        ),
        body: BlocBuilder<OrderCubit, OrderState>(
          builder: (context, state) {
            return _buildBody(state, filters);
          },
        ),
      ),
    );
  }

  List<_OrderFilter> _buildFilters(AppLocalizations l10n) {
    return [
      _OrderFilter(title: l10n.all),
      _OrderFilter(
        title: l10n.pendingPayment,
        statuses: const {OrderStatus.pendingPayment},
      ),
      _OrderFilter(
        title: l10n.processing,
        statuses: const {OrderStatus.paid, OrderStatus.processing},
      ),
      _OrderFilter(
        title: l10n.awaitingDelivery,
        statuses: const {OrderStatus.shipped, OrderStatus.delivered},
      ),
      _OrderFilter(
        title: l10n.completed,
        statuses: const {OrderStatus.completed},
      ),
      _OrderFilter(
        title: l10n.cancelled,
        statuses: const {OrderStatus.cancelled},
      ),
    ];
  }

  Widget _buildBody(OrderState state, List<_OrderFilter> filters) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == OrderLoadStatus.error && state.orders.isEmpty) {
      return _buildErrorView(state);
    }

    return TabBarView(
      children: filters.map((filter) {
        final orders = state.orders
            .where(filter.matches)
            .toList(growable: false);

        return _buildOrderList(orders);
      }).toList(),
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    if (orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 180),
            Icon(
              Icons.receipt_long_outlined,
              size: 72,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.noOrders,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 17,
                ),
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
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),

            const SizedBox(height: 16),

            Text(
              _orderErrorMessage(
                l10n,
                state.errorType,
                fallback: l10n.orderLoadFailed,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: () {
                _refresh();
              },
              child: Text(l10n.reload),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() {
    return context.read<OrderCubit>().refresh();
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
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.first;

    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

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
                      l10n.orderNumber(order.displayNumber),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
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
                        return SizedBox(
                          width: 72,
                          height: 72,
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
                          firstItem.productTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          order.items.length == 1
                              ? l10n.orderItemQuantity(firstItem.quantity)
                              : l10n.orderProductTypes(order.items.length),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),

                  const Spacer(),

                  Text(l10n.orderTotal),

                  Text(
                    'RM ${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colorScheme.primary,
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
  const _OrderStatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(_orderStatusTitle(l10n, status)),
    );
  }
}

class _OrderFilter {
  const _OrderFilter({required this.title, this.statuses});

  final String title;
  final Set<OrderStatus>? statuses;

  bool matches(Order order) {
    return statuses == null || statuses!.contains(order.status);
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
