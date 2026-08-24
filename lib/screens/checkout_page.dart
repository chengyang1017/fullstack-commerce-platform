import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/cart/cart_cubit.dart';
import '../cubits/checkout/checkout_cubit.dart';
import '../cubits/checkout/checkout_state.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/checkout_request.dart';
import '../models/order.dart';
import '../cubits/order/order_cubit.dart';
import 'address_form_page.dart';
import 'order_success_page.dart';
import 'payment_page.dart';

class CheckoutPage extends StatelessWidget {
  final CheckoutRequest request;

  const CheckoutPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, state) {
        final checkout = context.read<CheckoutCubit>();

        final loading =
            state.status == CheckoutStatus.initial || state.isLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('確認訂單')),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, state, checkout),
          bottomNavigationBar: loading || request.items.isEmpty
              ? null
              : _buildBottomBar(context, state, checkout),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CheckoutState state,
    CheckoutCubit checkout,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        _buildAddressSection(context, state, checkout),

        const SizedBox(height: 12),

        _buildProductSection(request.items),

        const SizedBox(height: 12),

        _buildShippingSection(state, checkout),

        const SizedBox(height: 12),

        _buildPaymentSection(state, checkout),

        const SizedBox(height: 12),

        _buildPriceSection(state, checkout),

        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressSection(
    BuildContext context,
    CheckoutState state,
    CheckoutCubit checkout,
  ) {
    return _SectionCard(
      title: '收貨地址',
      action: TextButton(
        onPressed: () {
          _addAddress(context);
        },
        child: const Text('新增'),
      ),
      child: state.addresses.isEmpty
          ? ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_location_alt_outlined),
              title: const Text('新增收貨地址'),
              subtitle: const Text('結算前必須填寫配送地址'),
              onTap: () {
                _addAddress(context);
              },
            )
          : Column(
              children: state.addresses.map((address) {
                return _AddressOption(
                  address: address,
                  selected: state.selectedAddress?.id == address.id,
                  onTap: () {
                    checkout.selectAddress(address.id);
                  },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildProductSection(List<CartItem> items) {
    return _SectionCard(
      title: '商品',
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.product.image,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        width: 64,
                        height: 64,
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
                        item.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'RM '
                        '${item.product.price.toStringAsFixed(2)}',
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

  Widget _buildShippingSection(CheckoutState state, CheckoutCubit checkout) {
    return _SectionCard(
      title: '配送方式',
      child: Column(
        children: ShippingMethod.values.map((method) {
          final selected = state.shippingMethod == method;

          return _OptionTile(
            title: method.title,
            subtitle:
                '${method.description} · '
                'RM ${method.fee.toStringAsFixed(2)}',
            selected: selected,
            onTap: () {
              checkout.selectShippingMethod(method);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentSection(CheckoutState state, CheckoutCubit checkout) {
    return _SectionCard(
      title: '付款方式',
      child: Column(
        children: PaymentMethod.values.map((method) {
          return _OptionTile(
            title: method.title,
            selected: state.paymentMethod == method,
            onTap: () {
              checkout.selectPaymentMethod(method);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSection(CheckoutState state, CheckoutCubit checkout) {
    return _SectionCard(
      title: '金額明細',
      child: Column(
        children: [
          _PriceRow(
            label: '商品小計',
            value: 'RM ${checkout.subtotal(request).toStringAsFixed(2)}',
          ),

          const SizedBox(height: 10),

          _PriceRow(
            label: '運費',
            value: 'RM ${state.shippingFee.toStringAsFixed(2)}',
          ),

          const Divider(height: 24),

          _PriceRow(
            label: '應付總額',
            value: 'RM ${checkout.total(request).toStringAsFixed(2)}',
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    CheckoutState state,
    CheckoutCubit checkout,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'RM '
                '${checkout.total(request).toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () {
                      _placeOrder(context);
                    },
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('提交訂單'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAddress(BuildContext context) async {
    final address = await Navigator.push<Address>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const AddressFormPage();
        },
      ),
    );

    if (address == null || !context.mounted) {
      return;
    }

    try {
      await context.read<CheckoutCubit>().addAddress(address);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存地址失敗')));
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
    final checkout = context.read<CheckoutCubit>();

    final cart = context.read<CartCubit>();

    final order = await checkout.placeOrder(request: request, cart: cart);

    if (!context.mounted) {
      return;
    }

    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(checkout.state.errorMessage ?? '建立訂單失敗')),
      );

      return;
    }

    BlocProvider.of<OrderCubit>(context).addCreatedOrder(order);

    if (order.paymentMethod == PaymentMethod.cashOnDelivery) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) {
            return OrderSuccessPage(
              order: order,
              cartClearFailed: checkout.state.cartClearFailed,
            );
          },
        ),
      );

      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          return PaymentFlowPage(order: order);
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const _SectionCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ?action,
              ],
            ),

            const SizedBox(height: 12),

            child,
          ],
        ),
      ),
    );
  }
}

class _AddressOption extends StatelessWidget {
  final Address address;
  final bool selected;
  final VoidCallback onTap;

  const _AddressOption({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(
        '${address.receiverName}  '
        '${address.phone}',
      ),
      subtitle: Text(address.fullAddress),
      trailing: address.isDefault ? const Chip(label: Text('預設')) : null,
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: emphasized ? 18 : 15,
      fontWeight: emphasized ? FontWeight.bold : FontWeight.normal,
      color: emphasized ? Colors.red : null,
    );

    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}
