import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferencesRepository {
  static const _themeModeKey = 'theme_mode';

  Future<ThemeMode> loadThemeMode() async {
    final preferences =
        await SharedPreferences.getInstance();

    final value =
        preferences.getString(
      _themeModeKey,
    );

    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(
    ThemeMode mode,
  ) async {
    final preferences =
        await SharedPreferences.getInstance();

    final value = switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };

    await preferences.setString(
      _themeModeKey,
      value,
    );
  }
}