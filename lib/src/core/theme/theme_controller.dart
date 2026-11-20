import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeStorage {
  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  static Future<ThemeMode> load() async {
    try {
      final value = await _storage.read(key: _key);
      switch (value) {
        case 'dark':
          return ThemeMode.dark;
        case 'system':
          return ThemeMode.system;
        case 'light':
        default:
          return ThemeMode.light;
      }
    } catch (_) {
      return ThemeMode.light;
    }
  }

  static Future<void> save(ThemeMode mode) async {
    try {
      final value = switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      };
      await _storage.write(key: _key, value: value);
    } catch (_) {}
  }

  static String label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
        return 'حسب النظام';
      case ThemeMode.light:
        return 'فاتح';
    }
  }

  static IconData icon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
    }
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier([ThemeMode initial = ThemeMode.light]) : super(initial);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ThemeModeStorage.save(mode);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
