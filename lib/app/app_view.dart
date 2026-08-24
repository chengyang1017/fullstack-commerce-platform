import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/locale/locale_cubit.dart';
import '../cubits/theme/theme_mode_cubit.dart';
import '../l10n/app_localizations.dart';
import '../screens/auth/customer_auth_gate.dart';
import 'app_theme.dart';

class AppView extends StatelessWidget {
  const AppView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      ThemeModeCubit,
      ThemeMode
    >(
      builder: (
        context,
        themeMode,
      ) {
        return BlocBuilder<
          LocaleCubit,
          Locale?
        >(
          builder: (
            context,
            locale,
          ) {
            return MaterialApp(
              debugShowCheckedModeBanner:
                  false,

              onGenerateTitle:
                  (context) {
                return AppLocalizations.of(
                  context,
                ).appTitle;
              },

              theme: AppTheme.light,

              darkTheme:
                  AppTheme.dark,

              themeMode:
                  themeMode,

              locale: locale,

              localizationsDelegates:
                  AppLocalizations
                      .localizationsDelegates,

              supportedLocales:
                  AppLocalizations
                      .supportedLocales,

              home:
                  const CustomerAuthGate(),
            );
          },
        );
      },
    );
  }
}