import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/i18n.dart';

const _prefsKey = 'medicare_hiv_locale';

// Mirrors the web app's cookie-persisted LanguageContext — same default-to-Indonesian
// decision, same "persist across restarts" requirement, just backed by SharedPreferences
// instead of a cookie since there's no server to read it from.
class LocaleController extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    AppStrings.locale = AppLocale.id;
    _loadPersisted();
    return AppLocale.id;
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == 'en') {
      state = AppLocale.en;
      AppStrings.locale = AppLocale.en;
    }
  }

  Future<void> toggle() async {
    state = state == AppLocale.id ? AppLocale.en : AppLocale.id;
    AppStrings.locale = state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, state.name);
  }
}

final localeProvider = NotifierProvider<LocaleController, AppLocale>(LocaleController.new);
