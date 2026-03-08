import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._localStorage) : super(ThemeMode.system);

  final LocalStorageService _localStorage;

  Future<void> loadTheme() async {
    final raw = _localStorage.getThemeMode();
    emit(_fromStorage(raw));
  }

  Future<void> setMode(ThemeMode mode) async {
    emit(mode);
    await _localStorage.saveThemeMode(_toStorage(mode));
  }

  ThemeMode _fromStorage(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _toStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
