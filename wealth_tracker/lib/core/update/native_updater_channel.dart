import 'package:flutter/services.dart';

const _channel = MethodChannel('money_hub/updater');

/// Whether the "Install unknown apps" toggle is granted for this app --
/// required before the system installer will act on a downloaded APK at
/// all (see AppUpdater.kt).
Future<bool> canInstallPackages() async {
  final result = await _channel.invokeMethod<bool>('canInstallPackages');
  return result ?? false;
}

/// Sends the user to the system screen to grant "Install unknown apps" for
/// this app -- there's no runtime permission dialog for this one.
Future<void> requestInstallPermission() {
  return _channel.invokeMethod('requestInstallPermission');
}

/// Launches the system package installer for the APK at [path].
Future<void> installApk(String path) {
  return _channel.invokeMethod('installApk', {'path': path});
}
