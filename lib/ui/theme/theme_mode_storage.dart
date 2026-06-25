import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  static Future<void> save(ThemeMode mode) async {
    await _storage.write(key: _key, value: mode.name);
  }

  static Future<ThemeMode?> read() async {
    final value = await _storage.read(key: _key);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }
}
