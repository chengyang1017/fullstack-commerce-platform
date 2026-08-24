import 'package:flutter/material.dart';

import '../../cubits/product/product_state.dart';
import '../../l10n/app_localizations.dart';

class HomeProductLoading extends StatelessWidget {
  const HomeProductLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class HomeProductError extends StatelessWidget {
  const HomeProductError({
    super.key,
    required this.type,
    required this.onRetry,
  });

  final ProductErrorType type;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final colorScheme = Theme.of(context).colorScheme;

    final message = switch (type) {
      ProductErrorType.loadFailed => l10n.productLoadFailed,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_outlined, size: 38, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.reload),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeProductEmpty extends StatelessWidget {
  const HomeProductEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 42,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
