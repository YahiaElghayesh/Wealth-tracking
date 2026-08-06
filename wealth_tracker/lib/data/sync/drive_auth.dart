import 'package:googleapis_auth/googleapis_auth.dart' as gapis;

/// One Drive scope: only the app's own hidden `appDataFolder`, never the
/// user's visible Drive files.
const driveScopes = ['https://www.googleapis.com/auth/drive.appdata'];

/// Bridges whatever Google sign-in mechanism a platform supports to a
/// `googleapis_auth` [AuthClient] that the Drive API client can use.
/// Android uses the native Google Sign-In SDK; Windows has no such SDK, so
/// it falls back to the standard OAuth "installed app" loopback flow.
abstract class DriveAuthProvider {
  /// Tries to restore a previous sign-in without showing any UI. Returns
  /// null if there's nothing to restore.
  Future<gapis.AuthClient?> signInSilently();

  /// Starts an interactive sign-in flow (opens a browser/account picker).
  Future<gapis.AuthClient> signIn();

  Future<void> signOut();
}

class DriveAuthException implements Exception {
  DriveAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
