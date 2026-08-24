import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/order.dart';
import 'order_details_page.dart';
import 'orders_page.dart';
import '../../../payment/presentation/pages/payment_page.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({
    super.key,
    required this.order,
    required this.cartClearFailed,
  });

  final Order order;
  final bool cartClearFailed;

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context);

    final colorScheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        title: Text(
          l10n
              .orderCreatedSuccessfully,
        ),
      ),
      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 90,
                color:
                    colorScheme.primary,
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                l10n.orderCreated,
                style:
                    const TextStyle(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                l10n.orderNumberValue(
                  order.displayNumber,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                l10n.paymentAmount(
                  order.total
                      .toStringAsFixed(
                    2,
                  ),
                ),
                style: TextStyle(
                  color:
                      colorScheme.primary,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              if (cartClearFailed) ...[
                const SizedBox(
                  height: 12,
                ),

                Text(
                  l10n
                      .cartClearFailedAfterOrder,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        colorScheme
                            .tertiary,
                  ),
                ),
              ],

              const SizedBox(
                height: 24,
              ),

              FilledButton(
                onPressed: () async {
                  if (order.status ==
                      OrderStatus
                          .pendingPayment) {
                    final
                        paymentSubmitted =
                        await Navigator
                            .push<bool>(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) {
                          return PaymentFlowPage(
                            order:
                                order,
                          );
                        },
                      ),
                    );

                    if (!context
                            .mounted ||
                        paymentSubmitted !=
                            true) {
                      return;
                    }
                  }

                  if (!context.mounted) {
                    return;
                  }

                  await Navigator
                      .pushReplacement<
                          void,
                          void>(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) {
                        return OrderDetailsPage(
                          orderId:
                              order.id,
                        );
                      },
                    ),
                  );
                },
                child: Text(
                  order.status ==
                          OrderStatus
                              .pendingPayment
                      ? l10n.payNow
                      : l10n
                          .viewThisOrder,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              OutlinedButton(
                onPressed: () {
                  Navigator
                      .pushReplacement<
                          void,
                          void>(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) {
                        return const OrdersPage();
                      },
                    ),
                  );
                },
                child: Text(
                  l10n.viewAllOrders,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              TextButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) =>
                        route.isFirst,
                  );
                },
                child: Text(
                  l10n
                      .continueShopping,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}