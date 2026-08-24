import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalePreferencesRepository {
  static const _localeKey = 'locale';

  Future<Locale?> loadLocale() async {
    final preferences =
        await SharedPreferences.getInstance();

    final value =
        preferences.getString(
      _localeKey,
    );

    return switch (value) {
      'zh' => const Locale('zh'),
      'en' => const Locale('en'),
      _ => null,
    };
  }

  Future<void> saveLocale(
    Locale? locale,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    if (locale == null) {
      await preferences.setString(
        _localeKey,
        'system',
      );

      return;
    }

    await preferences.setString(
      _localeKey,
      locale.languageCode,
    );
  }
}