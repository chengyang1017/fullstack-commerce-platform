import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    super.key,
    required this.onDailyDealsTap,
    required this.onNewArrivalsTap,
    required this.onBestSellersTap,
    required this.onCouponsTap,
  });

  final VoidCallback onDailyDealsTap;
  final VoidCallback onNewArrivalsTap;
  final VoidCallback onBestSellersTap;
  final VoidCallback onCouponsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final items = [
      _QuickActionItem(
        title: l10n.bestSellers,
        icon: Icons.local_fire_department_rounded,
        onTap: onBestSellersTap,
      ),
      _QuickActionItem(
        title: l10n.newArrivals,
        icon: Icons.auto_awesome_rounded,
        onTap: onNewArrivalsTap,
      ),
      _QuickActionItem(
        title: l10n.dailyDeals,
        icon: Icons.local_offer_rounded,
        onTap: onDailyDealsTap,
      ),
      _QuickActionItem(
        title: l10n.coupons,
        icon: Icons.confirmation_number_rounded,
        onTap: onCouponsTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 72,
        ),
        itemBuilder: (context, index) {
          return _QuickActionCard(item: items[index]);
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.item});

  final _QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 21,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
}
