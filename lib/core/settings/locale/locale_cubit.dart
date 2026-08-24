import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'locale_preferences_repository.dart';

class LocaleCubit
    extends Cubit<Locale?> {
  LocaleCubit({
    required LocalePreferencesRepository
        repository,
  })  : _repository = repository,
        super(null);

  final LocalePreferencesRepository
      _repository;

  Future<void> loadLocale() async {
    final locale =
        await _repository.loadLocale();

    emit(locale);
  }

  Future<void> useSystemLocale() {
    return setLocale(null);
  }

  Future<void> useChinese() {
    return setLocale(
      const Locale('zh'),
    );
  }

  Future<void> useEnglish() {
    return setLocale(
      const Locale('en'),
    );
  }

  Future<void> setLocale(
    Locale? locale,
  ) async {
    if (state == locale) {
      return;
    }

    emit(locale);

    await _repository.saveLocale(
      locale,
    );
  }
}