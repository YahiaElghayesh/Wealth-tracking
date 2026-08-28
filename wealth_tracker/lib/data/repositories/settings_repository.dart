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
  static const _smsCaptureEnabledKey = 'sms_capture_enabled';
  static const _androidServerClientIdKey = 'drive_android_server_client_id';

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

  /// True once the user has granted SMS + notification permission and
  /// turned on bank SMS detection from Settings — checked at every app
  /// start (Android only) to decide whether to re-register the SMS
  /// listener. Detecting a charge only shows a notification; nothing is
  /// recorded until the user acts on it.
  bool get smsCaptureEnabled => _prefs.getBool(_smsCaptureEnabledKey) ?? false;

  Future<void> setSmsCaptureEnabled(bool enabled) {
    return _prefs.setBool(_smsCaptureEnabledKey, enabled);
  }

  /// A Google Cloud "Web application" OAuth client ID (not the Android
  /// client). google_sign_in v7 requires this as `serverClientId` even on
  /// Android — without it, sign-in fails with "server client ID must be
  /// provided". Create one in the same Google Cloud project as the Android
  /// OAuth client — see the README.
  String? get androidServerClientId => _prefs.getString(_androidServerClientIdKey);

  Future<void> setAndroidServerClientId(String? clientId) async {
    if (clientId == null || clientId.isEmpty) {
      await _prefs.remove(_androidServerClientIdKey);
    } else {
      await _prefs.setString(_androidServerClientIdKey, clientId);
    }
  }
}
