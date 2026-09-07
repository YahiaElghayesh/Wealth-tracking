import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:wealth_tracker/core/update/app_update_service.dart';

/// Always serves [bytes] for any request, regardless of URL -- enough to
/// exercise [AppUpdateService.download]'s own logic (which only cares
/// about the response body) without a real network call.
class _FixedBodyAdapter implements HttpClientAdapter {
  _FixedBodyAdapter(this.bytes);

  final List<int> bytes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(bytes, 200);
  }

  @override
  void close({bool force = false}) {}
}

/// Serves a fixed JSON `/releases` list response for page 1 and an empty
/// list for every later page -- enough to exercise [AppUpdateService
/// .fetchLatest]'s own pagination/filtering logic without a real network
/// call.
class _ReleasesListAdapter implements HttpClientAdapter {
  _ReleasesListAdapter(this.releasesJson);

  final String releasesJson;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final page = int.tryParse('${options.queryParameters['page']}') ?? 1;
    final body = page == 1 ? releasesJson : '[]';
    return ResponseBody.fromBytes(
      utf8.encode(body),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;

  setUp(() => tempDir = Directory.systemTemp.createTempSync('app_update_test'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  const body = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  final correctSha256 = sha256.convert(body).toString();

  AppUpdateService serviceFor(List<int> bytes) {
    final dio = Dio()..httpClientAdapter = _FixedBodyAdapter(bytes);
    return AppUpdateService(dio: dio);
  }

  group('download checksum verification', () {
    test('keeps the file when it matches the expected SHA-256', () async {
      final service = serviceFor(body);
      final savePath = p.join(tempDir.path, 'update.apk');
      final update = AvailableUpdate(
        buildNumber: 1,
        assetDownloadUrl: 'https://example.invalid/update.apk',
        assetSizeBytes: body.length,
        expectedSha256: correctSha256,
      );

      await service.download(update, savePath);

      expect(File(savePath).existsSync(), isTrue);
      expect(File(savePath).readAsBytesSync(), body);
    });

    test(
      'deletes the file and throws when the bytes do not match the expected SHA-256',
      () async {
        final service = serviceFor(body);
        final savePath = p.join(tempDir.path, 'update.apk');
        final update = AvailableUpdate(
          buildNumber: 1,
          assetDownloadUrl: 'https://example.invalid/update.apk',
          assetSizeBytes: body.length,
          expectedSha256: ''.padLeft(64, '0'),
        );

        await expectLater(
          () => service.download(update, savePath),
          throwsA(isA<AppUpdateException>()),
        );
        expect(File(savePath).existsSync(), isFalse);
      },
    );

    test('skips verification (keeps the file) when expectedSha256 is null, '
        'for a release published before checksums existed', () async {
      final service = serviceFor(body);
      final savePath = p.join(tempDir.path, 'update.apk');
      final update = AvailableUpdate(
        buildNumber: 1,
        assetDownloadUrl: 'https://example.invalid/update.apk',
        assetSizeBytes: body.length,
        expectedSha256: null,
      );

      await service.download(update, savePath);

      expect(File(savePath).existsSync(), isTrue);
    });
  });

  group('fetchLatest', () {
    test(
      'ignores tags from other apps sharing this repo and returns the highest build-<N>',
      () async {
        final releases = jsonEncode([
          {'tag_name': 'mediahub-68', 'assets': <dynamic>[]},
          {
            'tag_name': 'build-134',
            'assets': [
              {
                'name': 'wealth-tracker-debug.apk',
                'browser_download_url': 'https://example.invalid/134.apk',
                'size': 111,
              },
            ],
          },
          {
            'tag_name': 'build-135',
            'assets': [
              {
                'name': 'wealth-tracker-debug.apk',
                'browser_download_url': 'https://example.invalid/135.apk',
                'size': 222,
              },
            ],
          },
        ]);
        final dio = Dio()..httpClientAdapter = _ReleasesListAdapter(releases);
        final service = AppUpdateService(dio: dio);

        final update = await service.fetchLatest();

        expect(update, isNotNull);
        expect(update!.buildNumber, 135);
        expect(update.assetDownloadUrl, 'https://example.invalid/135.apk');
      },
    );

    test(
      'returns null when nothing on the shared repo matches build-<N>',
      () async {
        final releases = jsonEncode([
          {'tag_name': 'mediahub-68', 'assets': <dynamic>[]},
        ]);
        final dio = Dio()..httpClientAdapter = _ReleasesListAdapter(releases);
        final service = AppUpdateService(dio: dio);

        expect(await service.fetchLatest(), isNull);
      },
    );
  });
}
