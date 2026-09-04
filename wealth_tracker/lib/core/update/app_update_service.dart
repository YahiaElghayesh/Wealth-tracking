import 'dart:io';

import 'package:crypto/crypto.dart';
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
    required this.expectedSha256,
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

  /// The hex SHA-256 digest CI computed for the exact `.apk` it published
  /// (see the workflow's own `.sha256` asset), or null for an older
  /// release published before that asset existed. [AppUpdateService
  /// .download] refuses to hand back a downloaded file that doesn't match
  /// this -- HTTPS already rules out in-transit tampering, but verifying
  /// the actual bytes against what CI itself built and hashed is a second,
  /// independent check that doesn't have to trust the download transport
  /// at all.
  final String? expectedSha256;
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
        // A real, confirmed report: "Check again" kept reporting the app
        // up to date against an *older* build, repeatably, well after a
        // newer one was verified (via the CI logs that publish it) to
        // already exist as this exact endpoint's marked "latest" release.
        // The only way an actual 2xx response to this exact URL keeps
        // disagreeing with the server's real state on every retry is a
        // cache sitting somewhere between this request and GitHub --
        // carrier/ISP transparent proxies caching a popular API host's GET
        // responses being the most common culprit, but this guards against
        // any such layer (an intermediate cache, or GitHub's own edge)
        // rather than trying to identify exactly which one. The query
        // param defeats a cache keyed purely on the URL; the headers ask
        // any HTTP-aware cache in the path not to serve or store a copy at
        // all -- belt and suspenders, since a misbehaving cache is
        // precisely the kind of thing that might ignore one but not both.
        queryParameters: {'_cacheBust': DateTime.now().millisecondsSinceEpoch},
        options: Options(
          headers: {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            'Cache-Control': 'no-cache, no-store',
            'Pragma': 'no-cache',
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
      String? checksumUrl;
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkAsset = asset;
        } else if (name.endsWith('.sha256')) {
          checksumUrl = asset['browser_download_url'] as String?;
        }
      }
      if (apkAsset == null) return null;

      final expectedSha256 = checksumUrl == null
          ? null
          : await _fetchChecksum(checksumUrl);

      return AvailableUpdate(
        buildNumber: buildNumber,
        assetDownloadUrl: apkAsset['browser_download_url'] as String,
        assetSizeBytes: apkAsset['size'] as int? ?? 0,
        expectedSha256: expectedSha256,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = status == 404
          ? 'No published build found (HTTP 404)'
          : e.message ?? 'network error';
      throw AppUpdateException(detail);
    }
  }

  /// Fetches the tiny plain-text `.sha256` asset and returns just the hex
  /// digest, lowercased and trimmed. A failure here (network hiccup, a
  /// release genuinely missing this asset despite listing it -- shouldn't
  /// happen, but this is a checksum's own fetch, not the APK's) falls back
  /// to null rather than blocking the update check entirely: the app
  /// still shows the update as available, [download] just has nothing to
  /// verify against for this one release.
  Future<String?> _fetchChecksum(String url) async {
    try {
      final response = await _dio.get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      final body = response.data?.trim().toLowerCase();
      if (body == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(body)) {
        return null;
      }
      return body;
    } on DioException {
      return null;
    }
  }

  /// Downloads the APK to [savePath], reporting 0.0-1.0 progress, then
  /// verifies it against [AvailableUpdate.expectedSha256] before returning
  /// -- see that field's own doc comment for why. A mismatch deletes the
  /// partial/tampered file and throws rather than leaving it in place for
  /// [AppUpdateController] to hand to the installer.
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

    final expected = update.expectedSha256;
    if (expected == null) return;

    final file = File(savePath);
    final digest = sha256.convert(await file.readAsBytes());
    if (digest.toString() != expected) {
      await file.delete();
      throw AppUpdateException(
        "Downloaded file didn't match the expected checksum -- discarded for safety. "
        'Please try again.',
      );
    }
  }
}
