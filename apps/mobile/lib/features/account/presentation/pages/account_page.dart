import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/settings/locale/locale_cubit.dart';
import '../../../../core/settings/theme/theme_mode_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/data/services/customer_auth_service.dart';
import '../../../auth/presentation/cubit/customer_auth_cubit.dart';
import '../../../auth/presentation/cubit/customer_auth_state.dart';
import '../../../order/presentation/cubit/order_cubit.dart';
import '../../../order/presentation/cubit/order_state.dart';
import '../../../order/presentation/pages/orders_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _avatarBusy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authService = context.read<CustomerAuthService>();

    return BlocBuilder<CustomerAuthCubit, CustomerAuthState>(
      buildWhen: (previous, current) {
        return previous.user != current.user ||
            previous.status != current.status;
      },
      builder: (context, authState) {
        return BlocSelector<OrderCubit, OrderState, int>(
          selector: (state) => state.orders.length,
          builder: (context, orderCount) {
            final customer = authState.user;
            final avatarUrl = authService.resolveMediaUrl(
              customer?.avatarUrl,
            );

            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.account),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24,
                ),
                children: [
                  _ProfileCard(
                    name: customer?.name ?? l10n.unknownUser,
                    email: customer?.email ?? '',
                    avatarUrl: avatarUrl,
                    busy: _avatarBusy,
                    changePhotoLabel: l10n.changePhoto,
                    onAvatarTap: customer == null
                        ? null
                        : () {
                            _showAvatarActions(
                              hasAvatar: customer.avatarUrl != null,
                            );
                          },
                  ),
                  const SizedBox(height: 20),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.receipt_long_outlined,
                        title: l10n.myOrders,
                        subtitle: orderCount == 0
                            ? l10n.viewOrderHistory
                            : l10n.orderCount(orderCount),
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrdersPage(),
                            ),
                          );
                        },
                      ),
                      const _SettingsDivider(),
                      BlocBuilder<ThemeModeCubit, ThemeMode>(
                        builder: (context, themeMode) {
                          return _SettingsTile(
                            icon: Icons.brightness_6_outlined,
                            title: l10n.appearance,
                            subtitle: _themeModeTitle(
                              l10n,
                              themeMode,
                            ),
                            onTap: () {
                              _showThemeModeSheet(
                                context,
                                themeMode,
                              );
                            },
                          );
                        },
                      ),
                      const _SettingsDivider(),
                      BlocBuilder<LocaleCubit, Locale?>(
                        builder: (context, locale) {
                          return _SettingsTile(
                            icon: Icons.language_outlined,
                            title: l10n.language,
                            subtitle: _localeTitle(
                              l10n,
                              locale,
                            ),
                            onTap: () {
                              _showLocaleSheet(
                                context,
                                locale,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.logout,
                        title: l10n.logout,
                        destructive: true,
                        showChevron: false,
                        onTap: () async {
                          await context
                              .read<CustomerAuthCubit>()
                              .logout();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAvatarActions({
    required bool hasAvatar,
  }) async {
    if (_avatarBusy) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    12,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.profilePhoto,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                  ),
                  title: Text(l10n.chooseFromGallery),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      _AvatarAction.choose,
                    );
                  },
                ),
                if (hasAvatar)
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      l10n.removePhoto,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        _AvatarAction.remove,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

    switch (action) {
      case _AvatarAction.choose:
        await _pickAvatar();
      case _AvatarAction.remove:
        await _removeAvatar();
      case null:
        return;
    }
  }

  Future<void> _pickAvatar() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() {
      _avatarBusy = true;
    });

    try {
      final bytes = await pickedFile.readAsBytes();

      if (!mounted) {
        return;
      }

      await context.read<CustomerAuthCubit>().uploadAvatar(
        bytes: bytes,
        fileName: pickedFile.name,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).avatarUpdated,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).avatarUpdateFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _avatarBusy = false;
        });
      }
    }
  }

  Future<void> _removeAvatar() async {
    if (_avatarBusy) {
      return;
    }

    setState(() {
      _avatarBusy = true;
    });

    try {
      await context.read<CustomerAuthCubit>().removeAvatar();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).avatarRemoved,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).avatarUpdateFailed,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _avatarBusy = false;
        });
      }
    }
  }

  static String _themeModeTitle(
    AppLocalizations l10n,
    ThemeMode mode,
  ) {
    return switch (mode) {
      ThemeMode.system => l10n.followSystem,
      ThemeMode.light => l10n.light,
      ThemeMode.dark => l10n.dark,
    };
  }

  static String _localeTitle(
    AppLocalizations l10n,
    Locale? locale,
  ) {
    if (locale == null) {
      return l10n.followSystemLanguage;
    }

    return switch (locale.languageCode) {
      'zh' => l10n.chinese,
      'en' => l10n.english,
      _ => l10n.followSystemLanguage,
    };
  }

  static Future<void> _showThemeModeSheet(
    BuildContext context,
    ThemeMode currentMode,
  ) {
    final l10n = AppLocalizations.of(context);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetTitle(title: l10n.appearance),
                _ThemeModeTile(
                  icon: Icons.phone_android,
                  title: l10n.followSystem,
                  subtitle: l10n.followSystemThemeDescription,
                  mode: ThemeMode.system,
                  currentMode: currentMode,
                  onSelected: (mode) {
                    context
                        .read<ThemeModeCubit>()
                        .setThemeMode(mode);
                    Navigator.pop(sheetContext);
                  },
                ),
                _ThemeModeTile(
                  icon: Icons.light_mode_outlined,
                  title: l10n.light,
                  subtitle: l10n.lightThemeDescription,
                  mode: ThemeMode.light,
                  currentMode: currentMode,
                  onSelected: (mode) {
                    context
                        .read<ThemeModeCubit>()
                        .setThemeMode(mode);
                    Navigator.pop(sheetContext);
                  },
                ),
                _ThemeModeTile(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.dark,
                  subtitle: l10n.darkThemeDescription,
                  mode: ThemeMode.dark,
                  currentMode: currentMode,
                  onSelected: (mode) {
                    context
                        .read<ThemeModeCubit>()
                        .setThemeMode(mode);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showLocaleSheet(
    BuildContext context,
    Locale? currentLocale,
  ) {
    final l10n = AppLocalizations.of(context);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetTitle(title: l10n.language),
                _LocaleTile(
                  icon: Icons.phone_android,
                  title: l10n.followSystemLanguage,
                  subtitle: l10n.followSystemLanguageDescription,
                  locale: null,
                  currentLocale: currentLocale,
                  onSelected: (locale) {
                    context.read<LocaleCubit>().setLocale(locale);
                    Navigator.pop(sheetContext);
                  },
                ),
                _LocaleTile(
                  icon: Icons.translate,
                  title: l10n.chinese,
                  subtitle: l10n.chineseDescription,
                  locale: const Locale('zh'),
                  currentLocale: currentLocale,
                  onSelected: (locale) {
                    context.read<LocaleCubit>().setLocale(locale);
                    Navigator.pop(sheetContext);
                  },
                ),
                _LocaleTile(
                  icon: Icons.language,
                  title: l10n.english,
                  subtitle: l10n.englishDescription,
                  locale: const Locale('en'),
                  currentLocale: currentLocale,
                  onSelected: (locale) {
                    context.read<LocaleCubit>().setLocale(locale);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _AvatarAction {
  choose,
  remove,
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.busy,
    required this.changePhotoLabel,
    required this.onAvatarTap,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final bool busy;
  final String changePhotoLabel;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Semantics(
            button: onAvatarTap != null,
            label: changePhotoLabel,
            child: GestureDetector(
              onTap: busy ? null : onAvatarTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _AvatarImage(
                    name: name,
                    avatarUrl: avatarUrl,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: busy
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt_outlined,
                                size: 17,
                                color: colorScheme.onPrimary,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.name,
    required this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget fallback() {
      return Container(
        width: 84,
        height: 84,
        alignment: Alignment.center,
        color: colorScheme.secondaryContainer,
        child: name.isEmpty
            ? Icon(
                Icons.person,
                size: 38,
                color: colorScheme.onSecondaryContainer,
              )
            : Text(
                name.characters.first.toUpperCase(),
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    }

    return ClipOval(
      child: avatarUrl == null
          ? fallback()
          : Image.network(
              avatarUrl!,
              width: 84,
              height: 84,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.45),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = destructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: destructive
                    ? colorScheme.errorContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 21,
                color: destructive
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        12,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.currentMode,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeMode mode;
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = mode == currentMode;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: () {
        onSelected(mode);
      },
    );
  }
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.locale,
    required this.currentLocale,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Locale? locale;
  final Locale? currentLocale;
  final ValueChanged<Locale?> onSelected;

  bool get _selected {
    if (locale == null && currentLocale == null) {
      return true;
    }

    return locale?.languageCode == currentLocale?.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: _selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: () {
        onSelected(locale);
      },
    );
  }
}
