import 'package:dio/dio.dart';

/// The GitHub repo this app's automated debug builds publish to -- see
/// `.github/workflows/build-apk.yml`'s "Publish GitHub Release" step, which
/// tags every build `build-<run-number>` and marks it the release's
/// "latest". Deliberately a *separate*, *public* repo from this app's own
/// (private) source repo -- a release published here needs no
/// authentication at all to read or download, so the installed app never
/// has to carry a GitHub credential of any kind. The CI workflow still
/// needs one to *publish* here (a cross-repo write, which always requires
/// some credential no matter how it's done) -- see that workflow's own
/// `RELEASES_REPO_TOKEN` secret -- but that token lives only in CI, never
/// baked into anything a user installs.
const _owner = 'YahiaElghayesh';
const _repo = 'app-releases';

class AvailableUpdate {
  const AvailableUpdate({
    required this.buildNumber,
    required this.assetDownloadUrl,
    required this.assetSizeBytes,
  });

  /// Parsed from the release's `build-<N>` tag -- exactly the
  /// `--build-number` CI passed to `flutter build apk`, so it's directly
  /// comparable to this device's own installed `PackageInfo.buildNumber`.
  final int buildNumber;

  /// The release asset's plain public URL (`browser_download_url`) --
  /// unlike a private repo, a public release asset is a normal HTTPS URL
  /// anyone can fetch directly, no API endpoint or auth header needed.
  final String assetDownloadUrl;

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

  /// Null means a release exists but has no usable `.apk` asset -- treated
  /// as "nothing to update to" rather than an error, since that shouldn't
  /// normally happen from CI's own release step.
  Future<AvailableUpdate?> fetchLatest() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        options: Options(
          headers: {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
          },
        ),
      );
      final tag = response.data?['tag_name'] as String?;
      final buildNumber = tag == null
          ? null
          : int.tryParse(tag.replaceFirst('build-', ''));
      if (buildNumber == null) return null;

      final assets = response.data?['assets'] as List<dynamic>? ?? [];
      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        if (asset is Map<String, dynamic> &&
            (asset['name'] as String? ?? '').endsWith('.apk')) {
          apkAsset = asset;
          break;
        }
      }
      if (apkAsset == null) return null;

      return AvailableUpdate(
        buildNumber: buildNumber,
        assetDownloadUrl: apkAsset['browser_download_url'] as String,
        assetSizeBytes: apkAsset['size'] as int? ?? 0,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = status == 404
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
        update.assetDownloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) onProgress(received / total);
        },
      );
    } on DioException catch (e) {
      throw AppUpdateException(e.message ?? 'download failed');
    }
  }
}
