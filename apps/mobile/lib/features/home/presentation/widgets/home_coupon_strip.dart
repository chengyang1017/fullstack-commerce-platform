import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HomeCouponStrip extends StatelessWidget {
  const HomeCouponStrip({super.key, required this.onCouponTap});

  final VoidCallback onCouponTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.coupons,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),

        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _CouponCard(
                amount: '20',
                colorScheme: colorScheme,
                onTap: onCouponTap,
              ),

              const SizedBox(width: 10),

              _CouponCard(
                amount: '30',
                colorScheme: colorScheme,
                onTap: onCouponTap,
              ),

              const SizedBox(width: 10),

              _CouponCard(
                amount: '50',
                colorScheme: colorScheme,
                onTap: onCouponTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.amount,
    required this.colorScheme,
    required this.onTap,
  });

  final String amount;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'RM $amount',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
