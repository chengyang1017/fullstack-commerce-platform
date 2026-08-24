import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_preferences_repository.dart';

class ThemeModeCubit
    extends Cubit<ThemeMode> {
  ThemeModeCubit({
    required ThemePreferencesRepository
        repository,
  })  : _repository = repository,
        super(ThemeMode.system);

  final ThemePreferencesRepository
      _repository;

  Future<void> loadThemeMode() async {
    final mode =
        await _repository.loadThemeMode();

    emit(mode);
  }

  Future<void> useSystemTheme() {
    return setThemeMode(
      ThemeMode.system,
    );
  }

  Future<void> useLightTheme() {
    return setThemeMode(
      ThemeMode.light,
    );
  }

  Future<void> useDarkTheme() {
    return setThemeMode(
      ThemeMode.dark,
    );
  }

  Future<void> setThemeMode(
    ThemeMode mode,
  ) async {
    if (state == mode) {
      return;
    }

    // 先立即更新 UI。
    emit(mode);

    // 再保存用户选择。
    await _repository.saveThemeMode(
      mode,
    );
  }
}