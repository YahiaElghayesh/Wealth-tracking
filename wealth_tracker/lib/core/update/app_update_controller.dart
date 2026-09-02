import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'app_update_service.dart';
import 'native_updater_channel.dart';

enum AppUpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  downloaded,
  error,
}

class AppUpdateState {
  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.currentBuildNumber = 0,
    this.available,
    this.downloadProgress = 0,
    this.downloadedPath,
    this.errorMessage,
  });

  final AppUpdateStatus status;
  final int currentBuildNumber;
  final AvailableUpdate? available;
  final double downloadProgress;
  final String? downloadedPath;
  final String? errorMessage;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    int? currentBuildNumber,
    AvailableUpdate? available,
    double? downloadProgress,
    String? downloadedPath,
    String? errorMessage,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      available: available ?? this.available,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedPath: downloadedPath ?? this.downloadedPath,
      errorMessage: errorMessage,
    );
  }
}

/// Drives Settings > App updates. Every build CI produces is tagged
/// `build-<run-number>` and has that exact number baked in as its own
/// versionCode (see build-apk.yml's `--build-number`), so "is a newer
/// build available" is a plain integer comparison -- no semver parsing.
class AppUpdateController extends Notifier<AppUpdateState> {
  final _service = AppUpdateService();

  @override
  AppUpdateState build() => const AppUpdateState();

  Future<void> check() async {
    state = state.copyWith(
      status: AppUpdateStatus.checking,
      errorMessage: null,
    );
    // Reading the installed build number is a local, offline call --
    // recorded into state immediately, before the network call below that
    // can throw (most commonly because this build has no
    // APP_UPDATE_TOKEN configured, see isUpdateCheckConfigured), so the
    // installed build number is always known even when the rest of the
    // check can't run. Previously this only ever landed in state after
    // fetchLatest() succeeded, so a build without that token showed no
    // build number at all -- leaving no way to tell what was actually
    // installed, which is exactly the information needed to confirm
    // whether a given bug report was against a build that already
    // contained a given fix.
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;
    state = state.copyWith(currentBuildNumber: currentBuild);
    try {
      final latest = await _service.fetchLatest();
      if (latest == null || latest.buildNumber <= currentBuild) {
        state = state.copyWith(status: AppUpdateStatus.upToDate);
      } else {
        state = state.copyWith(
          status: AppUpdateStatus.updateAvailable,
          available: latest,
        );
      }
    } on AppUpdateException catch (e) {
      state = state.copyWith(
        status: AppUpdateStatus.error,
        errorMessage: e.message,
      );
    }
  }

  Future<void> downloadAndInstall() async {
    final update = state.available;
    if (update == null) return;

    state = state.copyWith(
      status: AppUpdateStatus.downloading,
      downloadProgress: 0,
    );
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/wealth-tracker-update-${update.buildNumber}.apk';
      await _service.download(
        update,
        path,
        // Notifier's `state` setter can be called any time the notifier is
        // alive, including from inside this callback mid-download.
        onProgress: (progress) =>
            state = state.copyWith(downloadProgress: progress),
      );
      state = state.copyWith(
        status: AppUpdateStatus.downloaded,
        downloadedPath: path,
      );
      await _promptInstall(path);
    } on AppUpdateException catch (e) {
      state = state.copyWith(
        status: AppUpdateStatus.error,
        errorMessage: e.message,
      );
    }
  }

  /// Re-invoked after the user returns from the "Install unknown apps"
  /// settings screen, or taps "Install" again on an already-downloaded
  /// update.
  Future<void> retryInstall() async {
    final path = state.downloadedPath;
    if (path != null) await _promptInstall(path);
  }

  Future<void> _promptInstall(String path) async {
    if (!await canInstallPackages()) {
      // No callback for "user came back" -- they land back on this screen
      // and tap Install again, which re-checks and this time (once granted)
      // proceeds straight to the installer.
      await requestInstallPermission();
      return;
    }
    await installApk(path);
  }
}

final appUpdateControllerProvider =
    NotifierProvider<AppUpdateController, AppUpdateState>(
      AppUpdateController.new,
    );
