import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;

import '../repositories/settings_repository.dart';
import 'drive_auth.dart';

/// Android sign-in via the native Google Sign-In SDK. Requires an Android
/// OAuth client to be registered in Google Cloud Console for this app's
/// package name + signing certificate SHA-1 — see the README. google_sign_in
/// v7 also requires a *Web application* OAuth client ID passed as
/// `serverClientId` (yes, on Android too) or sign-in fails with "server
/// client ID must be provided on Android"; the user pastes that one into
/// Settings since it can't be baked into the app.
class AndroidDriveAuthProvider implements DriveAuthProvider {
  AndroidDriveAuthProvider(this._settings);

  final SettingsRepository _settings;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final serverClientId = _settings.androidServerClientId;
    if (serverClientId == null || serverClientId.isEmpty) {
      throw DriveAuthException(
        'Add a Google Web Client ID in Settings first (Google Drive sync section).',
      );
    }
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  Future<gapis.AuthClient?> _authClientFor(
    GoogleSignInClientAuthorization? authorization,
  ) async {
    if (authorization == null) return null;
    return authorization.authClient(scopes: driveScopes);
  }

  @override
  Future<gapis.AuthClient?> signInSilently() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.attemptLightweightAuthentication();
    if (account == null) return null;
    final authorization =
        await account.authorizationClient.authorizationForScopes(driveScopes);
    return _authClientFor(authorization);
  }

  @override
  Future<gapis.AuthClient> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final authorization = await account.authorizationClient.authorizeScopes(driveScopes);
      return authorization.authClient(scopes: driveScopes);
    } on GoogleSignInException catch (e) {
      throw DriveAuthException(e.description ?? e.code.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}
