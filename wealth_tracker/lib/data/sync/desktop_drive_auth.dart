import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart' as gapis_io;
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../repositories/settings_repository.dart';
import 'drive_auth.dart';

/// Windows (and other desktop platforms) have no native Google Sign-In SDK,
/// so this uses the standard OAuth "installed app" loopback flow: a browser
/// tab opens for consent, and `googleapis_auth` spins up a temporary local
/// server to catch the redirect. Requires a "Desktop app" OAuth client from
/// Google Cloud Console — see the README.
class DesktopDriveAuthProvider implements DriveAuthProvider {
  DesktopDriveAuthProvider(this._settings);

  final SettingsRepository _settings;

  gapis.ClientId _requireClientId() {
    final id = _settings.desktopClientId;
    final secret = _settings.desktopClientSecret;
    if (id == null || id.isEmpty) {
      throw DriveAuthException('Add a Desktop OAuth Client ID in Settings first.');
    }
    return gapis.ClientId(id, secret);
  }

  @override
  Future<gapis.AuthClient?> signInSilently() async {
    final raw = _settings.desktopCredentialsJson;
    if (raw == null) return null;
    final id = _settings.desktopClientId;
    if (id == null || id.isEmpty) return null;

    try {
      final credentials = gapis.AccessCredentials.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (credentials.refreshToken == null) return null;
      return gapis.autoRefreshingClient(_requireClientId(), credentials, http.Client());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<gapis.AuthClient> signIn() async {
    final clientId = _requireClientId();
    final client = await gapis_io.clientViaUserConsent(clientId, driveScopes, (url) async {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw DriveAuthException('Could not open browser for Google sign-in: $url');
      }
    });
    await _settings.setDesktopCredentialsJson(jsonEncode(client.credentials.toJson()));
    return client;
  }

  @override
  Future<void> signOut() async {
    await _settings.setDesktopCredentialsJson(null);
  }
}
