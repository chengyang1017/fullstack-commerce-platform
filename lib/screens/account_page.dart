import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth/customer_auth_cubit.dart';
import '../cubits/auth/customer_auth_state.dart';
import '../cubits/locale/locale_cubit.dart';
import '../cubits/order/order_cubit.dart';
import '../cubits/order/order_state.dart';
import '../cubits/theme/theme_mode_cubit.dart';
import '../l10n/app_localizations.dart';
import 'orders_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context);

    return BlocBuilder<
      CustomerAuthCubit,
      CustomerAuthState
    >(
      buildWhen: (
        previous,
        current,
      ) {
        return previous.user !=
            current.user;
      },
      builder: (
        context,
        authState,
      ) {
        return BlocSelector<
          OrderCubit,
          OrderState,
          int
        >(
          selector: (state) {
            return state.orders.length;
          },
          builder: (
            context,
            orderCount,
          ) {
            final customer =
                authState.user;

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  l10n.account,
                ),
              ),
              body: ListView(
                children: [
                  _AccountHeader(
                    name:
                        customer?.name ??
                            l10n
                                .unknownUser,
                    email:
                        customer?.email ??
                            '',
                  ),

                  const Divider(
                    height: 1,
                  ),

                  ListTile(
                    leading:
                        const Icon(
                      Icons
                          .receipt_long_outlined,
                    ),
                    title: Text(
                      l10n.myOrders,
                    ),
                    subtitle: Text(
                      orderCount == 0
                          ? l10n
                              .viewOrderHistory
                          : l10n
                              .orderCount(
                              orderCount,
                            ),
                    ),
                    trailing:
                        const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (
                            context,
                          ) {
                            return const OrdersPage();
                          },
                        ),
                      );
                    },
                  ),

                  const Divider(
                    height: 1,
                  ),

                  BlocBuilder<
                    ThemeModeCubit,
                    ThemeMode
                  >(
                    builder: (
                      context,
                      themeMode,
                    ) {
                      return ListTile(
                        leading:
                            const Icon(
                          Icons
                              .brightness_6_outlined,
                        ),
                        title: Text(
                          l10n.appearance,
                        ),
                        subtitle: Text(
                          _themeModeTitle(
                            l10n,
                            themeMode,
                          ),
                        ),
                        trailing:
                            const Icon(
                          Icons.chevron_right,
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

                  const Divider(
                    height: 1,
                  ),

                  BlocBuilder<
                    LocaleCubit,
                    Locale?
                  >(
                    builder: (
                      context,
                      locale,
                    ) {
                      return ListTile(
                        leading:
                            const Icon(
                          Icons
                              .language_outlined,
                        ),
                        title: Text(
                          l10n.language,
                        ),
                        subtitle: Text(
                          _localeTitle(
                            l10n,
                            locale,
                          ),
                        ),
                        trailing:
                            const Icon(
                          Icons.chevron_right,
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

                  const Divider(
                    height: 1,
                  ),

                  ListTile(
                    leading:
                        const Icon(
                      Icons.logout,
                    ),
                    title: Text(
                      l10n.logout,
                    ),
                    onTap: () async {
                      await context
                          .read<
                              CustomerAuthCubit>()
                          .logout();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _themeModeTitle(
    AppLocalizations l10n,
    ThemeMode mode,
  ) {
    return switch (mode) {
      ThemeMode.system =>
        l10n.followSystem,
      ThemeMode.light =>
        l10n.light,
      ThemeMode.dark =>
        l10n.dark,
    };
  }

  static String _localeTitle(
    AppLocalizations l10n,
    Locale? locale,
  ) {
    if (locale == null) {
      return l10n
          .followSystemLanguage;
    }

    return switch (
        locale.languageCode) {
      'zh' => l10n.chinese,
      'en' => l10n.english,
      _ => l10n
          .followSystemLanguage,
    };
  }

  static Future<void>
      _showThemeModeSheet(
    BuildContext context,
    ThemeMode currentMode,
  ) {
    final l10n =
        AppLocalizations.of(context);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (
        sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                _SheetTitle(
                  title:
                      l10n.appearance,
                ),

                _ThemeModeTile(
                  icon:
                      Icons.phone_android,
                  title:
                      l10n.followSystem,
                  subtitle: l10n
                      .followSystemThemeDescription,
                  mode:
                      ThemeMode.system,
                  currentMode:
                      currentMode,
                  onSelected: (
                    mode,
                  ) {
                    context
                        .read<
                            ThemeModeCubit>()
                        .setThemeMode(
                          mode,
                        );

                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),

                _ThemeModeTile(
                  icon: Icons
                      .light_mode_outlined,
                  title: l10n.light,
                  subtitle: l10n
                      .lightThemeDescription,
                  mode:
                      ThemeMode.light,
                  currentMode:
                      currentMode,
                  onSelected: (
                    mode,
                  ) {
                    context
                        .read<
                            ThemeModeCubit>()
                        .setThemeMode(
                          mode,
                        );

                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),

                _ThemeModeTile(
                  icon: Icons
                      .dark_mode_outlined,
                  title: l10n.dark,
                  subtitle: l10n
                      .darkThemeDescription,
                  mode:
                      ThemeMode.dark,
                  currentMode:
                      currentMode,
                  onSelected: (
                    mode,
                  ) {
                    context
                        .read<
                            ThemeModeCubit>()
                        .setThemeMode(
                          mode,
                        );

                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void>
      _showLocaleSheet(
    BuildContext context,
    Locale? currentLocale,
  ) {
    final l10n =
        AppLocalizations.of(context);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (
        sheetContext,
      ) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                _SheetTitle(
                  title:
                      l10n.language,
                ),

                _LocaleTile(
                  icon:
                      Icons.phone_android,
                  title: l10n
                      .followSystemLanguage,
                  subtitle: l10n
                      .followSystemLanguageDescription,
                  locale: null,
                  currentLocale:
                      currentLocale,
                  onSelected: (
                    locale,
                  ) {
                    context
                        .read<
                            LocaleCubit>()
                        .setLocale(
                          locale,
                        );

                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),

                _LocaleTile(
                  icon:
                      Icons.translate,
                  title:
                      l10n.chinese,
                  subtitle: l10n
                      .chineseDescription,
                  locale:
                      const Locale(
                    'zh',
                  ),
                  currentLocale:
                      currentLocale,
                  onSelected: (
                    locale,
                  ) {
                    context
                        .read<
                            LocaleCubit>()
                        .setLocale(
                          locale,
                        );

                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),

                _LocaleTile(
                  icon:
                      Icons.language,
                  title:
                      l10n.english,
                  subtitle: l10n
                      .englishDescription,
                  locale:
                      const Locale(
                    'en',
                  ),
                  currentLocale:
                      currentLocale,
                  onSelected: (
                    locale,
                  ) {
                    context
                        .read<
                            LocaleCubit>()
                        .setLocale(
                          locale,
                        );

                    Navigator.pop(
                      sheetContext,
                    );
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

class _SheetTitle
    extends StatelessWidget {
  const _SheetTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        12,
      ),
      child: Align(
        alignment:
            Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class _ThemeModeTile
    extends StatelessWidget {
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

  final ValueChanged<ThemeMode>
      onSelected;

  @override
  Widget build(BuildContext context) {
    final selected =
        mode == currentMode;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            )
          : const Icon(
              Icons.circle_outlined,
            ),
      onTap: () {
        onSelected(mode);
      },
    );
  }
}

class _LocaleTile
    extends StatelessWidget {
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

  final ValueChanged<Locale?>
      onSelected;

  bool get _selected {
    if (locale == null &&
        currentLocale == null) {
      return true;
    }

    return locale?.languageCode ==
        currentLocale?.languageCode;
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
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            )
          : const Icon(
              Icons.circle_outlined,
            ),
      onTap: () {
        onSelected(locale);
      },
    );
  }
}

class _AccountHeader
    extends StatelessWidget {
  const _AccountHeader({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            child: name.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 36,
                  )
                : Text(
                    name.characters.first
                        .toUpperCase(),
                    style:
                        const TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  email,
                  style: TextStyle(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}