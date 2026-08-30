import 'package:dio/dio.dart';

/// The GitHub repo this app's automated debug builds publish to -- see
/// `.github/workflows/build-apk.yml`'s "Publish GitHub Release" step, which
/// tags every build `build-<run-number>` and marks it the release's
/// "latest".
const _owner = 'YahiaElghayesh';
const _repo = 'Wealth-tracking';

/// Baked in at build time from the `APP_UPDATE_TOKEN` repo secret (see
/// build-apk.yml) -- a fine-grained, read-only, repo-scoped GitHub token.
/// Needed because the repo is private: without it, even reading the
/// Releases API (let alone downloading an asset) 404s. Empty in any build
/// that wasn't produced by CI with that secret configured (e.g. a local
/// `flutter run`), in which case update checking is deliberately disabled
/// (see [isUpdateCheckConfigured]) rather than failing with a confusing
/// 401/404 every time.
const _updateToken = String.fromEnvironment('GITHUB_UPDATE_TOKEN');

bool get isUpdateCheckConfigured => _updateToken.isNotEmpty;

class AvailableUpdate {
  const AvailableUpdate({required this.buildNumber, required this.assetApiUrl, required this.assetSizeBytes});

  /// Parsed from the release's `build-<N>` tag -- exactly the
  /// `--build-number` CI passed to `flutter build apk`, so it's directly
  /// comparable to this device's own installed `PackageInfo.buildNumber`.
  final int buildNumber;

  /// The GitHub API asset endpoint (`.../releases/assets/<id>`), not the
  /// release's `browser_download_url` -- the latter 404s for a private
  /// repo without an authenticated browser session; the API endpoint with
  /// an `Accept: application/octet-stream` header is what actually returns
  /// the file for a bearer-token request.
  final String assetApiUrl;

  final int assetSizeBytes;
}

/// Thrown for any failure reaching/parsing the Releases API or downloading
/// the asset -- message is meant to be shown to the user as-is, same
/// pattern as [PriceFetchException] elsewhere in this app.
class AppUpdateException implements Exception {
  AppUpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Map<String, String> get _apiHeaders => {
    'Authorization': 'Bearer $_updateToken',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  /// Null means a release exists but has no usable `.apk` asset -- treated
  /// as "nothing to update to" rather than an error, since that shouldn't
  /// normally happen from CI's own release step.
  Future<AvailableUpdate?> fetchLatest() async {
    if (!isUpdateCheckConfigured) {
      throw AppUpdateException('Update checking isn\'t configured in this build (no APP_UPDATE_TOKEN).');
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        options: Options(headers: _apiHeaders),
      );
      final tag = response.data?['tag_name'] as String?;
      final buildNumber = tag == null ? null : int.tryParse(tag.replaceFirst('build-', ''));
      if (buildNumber == null) return null;

      final assets = response.data?['assets'] as List<dynamic>? ?? [];
      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        if (asset is Map<String, dynamic> && (asset['name'] as String? ?? '').endsWith('.apk')) {
          apkAsset = asset;
          break;
        }
      }
      if (apkAsset == null) return null;

      return AvailableUpdate(
        buildNumber: buildNumber,
        assetApiUrl: apkAsset['url'] as String,
        assetSizeBytes: apkAsset['size'] as int? ?? 0,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = status == 401 || status == 403
          ? 'Update token was rejected (expired or revoked?) (HTTP $status)'
          : status == 404
          ? 'No published build found (HTTP 404)'
          : e.message ?? 'network error';
      throw AppUpdateException(detail);
    }
  }

  /// Downloads the APK to [savePath], reporting 0.0-1.0 progress.
  Future<void> download(
    AvailableUpdate update,
    String savePath, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      await _dio.download(
        update.assetApiUrl,
        savePath,
        options: Options(headers: {..._apiHeaders, 'Accept': 'application/octet-stream'}),
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) onProgress(received / total);
        },
      );
    } on DioException catch (e) {
      throw AppUpdateException(e.message ?? 'download failed');
    }
  }
}
