import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The handful of [SettingsRepository] values that are genuine secrets --
/// a paid API key, an OAuth client secret, and persisted OAuth
/// access/refresh tokens -- kept out of [SharedPreferences] (a plain,
/// unencrypted file any code with access to the app's own storage
/// directory, e.g. on a rooted device, could read directly) and into the
/// platform's real secure storage instead: Android Keystore-backed
/// EncryptedSharedPreferences, iOS/macOS Keychain, Windows Credential
/// Manager.
///
/// Loaded once into memory at startup (see `main.dart`), the same pattern
/// this app already uses for [SharedPreferences] itself -- secure storage
/// reads are real async platform-channel calls, and every existing
/// [SettingsRepository] getter is synchronous, so the alternative would be
/// threading `Future`s through every call site that ever reads an API key.
/// A handful of low-value secrets cached in memory for a running app's
/// lifetime is a reasonable trade; every write still goes straight to the
/// secure backend, not just the cache.
class SecureSettingsStore {
  SecureSettingsStore._(this._storage, this._cache);

  final FlutterSecureStorage _storage;
  final Map<String, String?> _cache;

  static const _keys = [
    'metals_api_key',
    'drive_desktop_client_secret',
    'drive_desktop_credentials_json',
  ];

  /// [legacyPrefs] is where these same three keys used to live before this
  /// class existed -- an already-signed-in Drive session or a saved gold
  /// -price API key sitting there is real user setup, not something to
  /// silently drop out from under someone on their next update. Any of the
  /// three keys found there and not already present in secure storage gets
  /// copied over once and removed from [legacyPrefs], so upgrading is a
  /// one-time, invisible migration rather than a "sign in again" surprise.
  static Future<SecureSettingsStore> load(SharedPreferences legacyPrefs) async {
    const storage = FlutterSecureStorage();
    final cache = <String, String?>{};
    for (final key in _keys) {
      var value = await storage.read(key: key);
      if (value == null) {
        final legacy = legacyPrefs.getString(key);
        if (legacy != null && legacy.isNotEmpty) {
          await storage.write(key: key, value: legacy);
          await legacyPrefs.remove(key);
          value = legacy;
        }
      }
      cache[key] = value;
    }
    return SecureSettingsStore._(storage, cache);
  }

  String? get(String key) => _cache[key];

  Future<void> set(String key, String? value) async {
    _cache[key] = value;
    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }
}
