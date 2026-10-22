import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'app_locale';

  static Future<void> save(String languageCode) async {
    await _storage.write(key: _key, value: languageCode);
  }

  static Future<String?> read() async {
    return await _storage.read(key: _key);
  }
}
