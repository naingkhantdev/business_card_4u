import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/storage/locale_storage.dart';

const supportedAppLocales = [Locale('en'), Locale('my')];

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Default to English immediately so the app never blocks on this;
    // swap in the saved choice once storage answers.
    _restoreSaved();
    return const Locale('en');
  }

  Future<void> _restoreSaved() async {
    final saved = await LocaleStorage.read();
    if (saved == null) return;
    for (final locale in supportedAppLocales) {
      if (locale.languageCode == saved) {
        state = locale;
        return;
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await LocaleStorage.save(locale.languageCode);
  }
}
