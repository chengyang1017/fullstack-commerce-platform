import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/cart/cart_cubit.dart';
import '../cubits/checkout/checkout_cubit.dart';
import '../cubits/checkout/checkout_state.dart';
import '../cubits/order/order_cubit.dart';
import '../l10n/app_localizations.dart';
import '../models/address.dart';
import '../models/cart_item.dart';
import '../models/checkout_request.dart';
import '../models/order.dart';
import 'address_form_page.dart';
import 'order_success_page.dart';
import 'payment_page.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({
    super.key,
    required this.request,
  });

  final CheckoutRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context);

    return BlocBuilder<
      CheckoutCubit,
      CheckoutState
    >(
      builder: (
        context,
        state,
      ) {
        final checkout =
            context.read<CheckoutCubit>();

        final loading =
            state.status ==
                    CheckoutStatus.initial ||
                state.isLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.confirmOrder,
            ),
          ),
          body: loading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : _buildBody(
                  context,
                  state,
                  checkout,
                ),
          bottomNavigationBar:
              loading ||
                      request.items.isEmpty
                  ? null
                  : _buildBottomBar(
                      context,
                      state,
                      checkout,
                    ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CheckoutState state,
    CheckoutCubit checkout,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        100,
      ),
      children: [
        _buildAddressSection(
          context,
          state,
          checkout,
        ),

        const SizedBox(
          height: 12,
        ),

        _buildProductSection(
          context,
          request.items,
        ),

        const SizedBox(
          height: 12,
        ),

        _buildShippingSection(
          context,
          state,
          checkout,
        ),

        const SizedBox(
          height: 12,
        ),

        _buildPaymentSection(
          context,
          state,
          checkout,
        ),

        const SizedBox(
          height: 12,
        ),

        _buildPriceSection(
          context,
          state,
          checkout,
        ),

        if (state.errorType != null)
  Padding(
    padding: const EdgeInsets.only(
      top: 12,
    ),
    child: Text(
      _checkoutErrorMessage(
        AppLocalizations.of(context),
        state.errorType,
      ),
      style: TextStyle(
        color: colorScheme.error,
      ),
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
    final l10n =
        AppLocalizations.of(context);

    return _SectionCard(
      title:
          l10n.shippingAddress,
      action: TextButton(
        onPressed: () {
          _addAddress(context);
        },
        child: Text(
          l10n.add,
        ),
      ),
      child: state.addresses.isEmpty
          ? ListTile(
              contentPadding:
                  EdgeInsets.zero,
              leading: const Icon(
                Icons
                    .add_location_alt_outlined,
              ),
              title: Text(
                l10n
                    .addShippingAddress,
              ),
              subtitle: Text(
                l10n
                    .shippingAddressRequired,
              ),
              onTap: () {
                _addAddress(
                  context,
                );
              },
            )
          : Column(
              children:
                  state.addresses.map(
                (address) {
                  return _AddressOption(
                    address: address,
                    selected: state
                            .selectedAddress
                            ?.id ==
                        address.id,
                    onTap: () {
                      checkout
                          .selectAddress(
                        address.id,
                      );
                    },
                  );
                },
              ).toList(),
            ),
    );
  }

  Widget _buildProductSection(
    BuildContext context,
    List<CartItem> items,
  ) {
    final l10n =
        AppLocalizations.of(context);

    final colorScheme =
        Theme.of(context).colorScheme;

    return _SectionCard(
      title: l10n.products,
      child: Column(
        children: items.map(
          (item) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius
                            .circular(
                      8,
                    ),
                    child: Image.network(
                      item.product.image,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return SizedBox(
                          width: 64,
                          height: 64,
                          child:
                              ColoredBox(
                            color: colorScheme
                                .surfaceContainerHighest,
                            child: Icon(
                              Icons
                                  .broken_image_outlined,
                              color: colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          item.product
                              .title,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          'RM ${item.product.price.toStringAsFixed(2)}',
                          style:
                              TextStyle(
                            color:
                                colorScheme
                                    .primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '× ${item.quantity}',
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildShippingSection(
    BuildContext context,
    CheckoutState state,
    CheckoutCubit checkout,
  ) {
    final l10n =
        AppLocalizations.of(context);

    return _SectionCard(
      title:
          l10n.shippingMethod,
      child: Column(
        children:
            ShippingMethod.values.map(
          (method) {
            final selected =
                state.shippingMethod ==
                    method;

            return _OptionTile(
              title:
                  _shippingMethodTitle(
                l10n,
                method,
              ),
              subtitle:
                  '${_shippingMethodDescription(l10n, method)} · '
                  'RM ${method.fee.toStringAsFixed(2)}',
              selected: selected,
              onTap: () {
                checkout
                    .selectShippingMethod(
                  method,
                );
              },
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildPaymentSection(
    BuildContext context,
    CheckoutState state,
    CheckoutCubit checkout,
  ) {
    final l10n =
        AppLocalizations.of(context);

    return _SectionCard(
      title:
          l10n.paymentMethod,
      child: Column(
        children:
            PaymentMethod.values.map(
          (method) {
            return _OptionTile(
              title:
                  _paymentMethodTitle(
                l10n,
                method,
              ),
              selected:
                  state.paymentMethod ==
                      method,
              onTap: () {
                checkout
                    .selectPaymentMethod(
                  method,
                );
              },
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildPriceSection(
    BuildContext context,
    CheckoutState state,
    CheckoutCubit checkout,
  ) {
    final l10n =
        AppLocalizations.of(context);

    return _SectionCard(
      title:
          l10n.amountDetails,
      child: Column(
        children: [
          _PriceRow(
            label:
                l10n.productSubtotal,
            value:
                'RM ${checkout.subtotal(request).toStringAsFixed(2)}',
          ),

          const SizedBox(
            height: 10,
          ),

          _PriceRow(
            label:
                l10n.shippingFee,
            value:
                'RM ${state.shippingFee.toStringAsFixed(2)}',
          ),

          const Divider(
            height: 24,
          ),

          _PriceRow(
            label:
                l10n.amountDue,
            value:
                'RM ${checkout.total(request).toStringAsFixed(2)}',
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
    final colorScheme =
        Theme.of(context).colorScheme;

    final l10n =
        AppLocalizations.of(context);

    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.all(
          12,
        ),
        decoration: BoxDecoration(
          color:
              colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow
                  .withValues(
                alpha: 0.12,
              ),
              blurRadius: 8,
              offset:
                  const Offset(
                0,
                -2,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'RM ${checkout.total(request).toStringAsFixed(2)}',
                style: TextStyle(
                  color:
                      colorScheme.primary,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),

            FilledButton(
              onPressed:
                  state.isSubmitting
                      ? null
                      : () {
                          _placeOrder(
                            context,
                          );
                        },
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      l10n.placeOrder,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAddress(
    BuildContext context,
  ) async {
    final address =
        await Navigator.push<
            Address>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const AddressFormPage();
        },
      ),
    );

    if (address == null ||
        !context.mounted) {
      return;
    }

    try {
      await context
          .read<CheckoutCubit>()
          .addAddress(address);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      final l10n =
          AppLocalizations.of(
        context,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            l10n
                .saveAddressFailed,
          ),
        ),
      );
    }
  }

  Future<void> _placeOrder(
    BuildContext context,
  ) async {
    final checkout =
        context.read<CheckoutCubit>();

    final cart =
        context.read<CartCubit>();

    final order =
        await checkout.placeOrder(
      request: request,
      cart: cart,
    );

    if (!context.mounted) {
      return;
    }

    if (order == null) {
      final l10n =
          AppLocalizations.of(
        context,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
  _checkoutErrorMessage(
    l10n,
    checkout.state.errorType,
    fallback:
        l10n.createOrderFailed,
  ),
),
        ),
      );

      return;
    }

    context
        .read<OrderCubit>()
        .addCreatedOrder(
          order,
        );

    if (order.paymentMethod ==
        PaymentMethod
            .cashOnDelivery) {
      await Navigator
          .pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) {
            return OrderSuccessPage(
              order: order,
              cartClearFailed:
                  checkout
                      .state
                      .cartClearFailed,
            );
          },
        ),
      );

      return;
    }

    await Navigator
        .pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          return PaymentFlowPage(
            order: order,
          );
        },
      ),
    );
  }

  String _shippingMethodTitle(
    AppLocalizations l10n,
    ShippingMethod method,
  ) {
    return switch (method) {
      ShippingMethod.standard =>
        l10n.standardShipping,
      ShippingMethod.express =>
        l10n.expressShipping,
    };
  }

  String _shippingMethodDescription(
    AppLocalizations l10n,
    ShippingMethod method,
  ) {
    return switch (method) {
      ShippingMethod.standard =>
        l10n
            .standardShippingDescription,
      ShippingMethod.express =>
        l10n
            .expressShippingDescription,
    };
  }

  String _paymentMethodTitle(
    AppLocalizations l10n,
    PaymentMethod method,
  ) {
    return switch (method) {
      PaymentMethod
            .onlineBanking =>
        l10n.onlineBanking,
      PaymentMethod.card =>
        l10n.creditDebitCard,
      PaymentMethod
            .cashOnDelivery =>
        l10n.cashOnDelivery,
    };
  }

  String _checkoutErrorMessage(
  AppLocalizations l10n,
  CheckoutErrorType? type, {
  String? fallback,
}) {
  return switch (type) {
    CheckoutErrorType.loadFailed =>
      l10n.checkoutLoadFailed,

    CheckoutErrorType.emptyItems =>
      l10n.checkoutNoItems,

    CheckoutErrorType.addressRequired =>
      l10n.checkoutSelectAddress,

    CheckoutErrorType.createOrderFailed =>
      l10n.createOrderFailed,

    null =>
      fallback ?? l10n.createOrderFailed,
  };
}
}

class _SectionCard
    extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
                ?action,
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            child,
          ],
        ),
      ),
    );
  }
}

class _AddressOption
    extends StatelessWidget {
  const _AddressOption({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final l10n =
        AppLocalizations.of(context);

    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected
            ? Icons.check_circle
            : Icons.circle_outlined,
        color: selected
            ? colorScheme.primary
            : colorScheme
                .onSurfaceVariant,
      ),
      title: Text(
        '${address.receiverName}  '
        '${address.phone}',
      ),
      subtitle: Text(
        address.fullAddress,
      ),
      trailing: address.isDefault
          ? Chip(
              label: Text(
                l10n.defaultAddress,
              ),
            )
          : null,
    );
  }
}

class _OptionTile
    extends StatelessWidget {
  const _OptionTile({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return ListTile(
      contentPadding:
          EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        selected
            ? Icons.check_circle
            : Icons.circle_outlined,
        color: selected
            ? colorScheme.primary
            : colorScheme
                .onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!),
    );
  }
}

class _PriceRow
    extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final style = TextStyle(
      fontSize:
          emphasized ? 18 : 15,
      fontWeight: emphasized
          ? FontWeight.bold
          : FontWeight.normal,
      color: emphasized
          ? colorScheme.primary
          : null,
    );

    return Row(
      children: [
        Text(label),
        const Spacer(),
        Text(
          value,
          style: style,
        ),
      ],
    );
  }
}