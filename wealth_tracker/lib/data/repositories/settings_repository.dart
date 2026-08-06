import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value settings backed by [SharedPreferences]. Anything that
/// belongs in the synced database (assets, ledger) lives in drift instead —
/// this is strictly per-device app configuration (API keys, tokens).
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _metalsApiKeyKey = 'metals_api_key';
  static const _desktopClientIdKey = 'drive_desktop_client_id';
  static const _desktopClientSecretKey = 'drive_desktop_client_secret';
  static const _desktopCredentialsKey = 'drive_desktop_credentials_json';
  static const _lastSyncedAtKey = 'drive_last_synced_at';

  String? get metalsApiKey => _prefs.getString(_metalsApiKeyKey);

  Future<void> setMetalsApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _prefs.remove(_metalsApiKeyKey);
    } else {
      await _prefs.setString(_metalsApiKeyKey, key);
    }
  }

  /// OAuth "Desktop app" client credentials, needed only on platforms
  /// without a native Google Sign-In SDK (i.e. Windows). Google issues a
  /// secret for this client type, but it's not treated as confidential for
  /// installed apps — see the README for how to create one.
  String? get desktopClientId => _prefs.getString(_desktopClientIdKey);
  String? get desktopClientSecret => _prefs.getString(_desktopClientSecretKey);

  Future<void> setDesktopOAuthClient({required String? clientId, required String? clientSecret}) async {
    if (clientId == null || clientId.isEmpty) {
      await _prefs.remove(_desktopClientIdKey);
    } else {
      await _prefs.setString(_desktopClientIdKey, clientId);
    }
    if (clientSecret == null || clientSecret.isEmpty) {
      await _prefs.remove(_desktopClientSecretKey);
    } else {
      await _prefs.setString(_desktopClientSecretKey, clientSecret);
    }
  }

  /// Persisted `AccessCredentials.toJson()` so desktop sign-in can be
  /// restored silently across app restarts without a browser round trip.
  String? get desktopCredentialsJson => _prefs.getString(_desktopCredentialsKey);

  Future<void> setDesktopCredentialsJson(String? json) async {
    if (json == null) {
      await _prefs.remove(_desktopCredentialsKey);
    } else {
      await _prefs.setString(_desktopCredentialsKey, json);
    }
  }

  DateTime? get lastSyncedAt {
    final raw = _prefs.getString(_lastSyncedAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastSyncedAt(DateTime time) {
    return _prefs.setString(_lastSyncedAtKey, time.toUtc().toIso8601String());
  }
}
