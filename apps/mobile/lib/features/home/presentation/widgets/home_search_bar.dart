import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.onScannerTap,
    required this.onSearchTap,
  });

  final VoidCallback onScannerTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onScannerTap,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 22,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onSearchTap,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 46,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.searchProductsBrands,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
