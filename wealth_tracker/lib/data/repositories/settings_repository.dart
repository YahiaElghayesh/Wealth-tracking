import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value settings backed by [SharedPreferences]. Anything that
/// belongs in the synced database (assets, ledger) lives in drift instead —
/// this is strictly per-device app configuration (API keys, tokens).
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _metalsApiKeyKey = 'metals_api_key';

  String? get metalsApiKey => _prefs.getString(_metalsApiKeyKey);

  Future<void> setMetalsApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _prefs.remove(_metalsApiKeyKey);
    } else {
      await _prefs.setString(_metalsApiKeyKey, key);
    }
  }
}
