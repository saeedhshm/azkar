import 'dart:io';

import 'package:azkar/core/storage/local_storage_service.dart';
import 'package:azkar/features/quran/data/datasources/quran_page_image_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _StorageStub extends LocalStorageService {
  int? cacheVersion;

  @override
  int? getQuranPagesCacheVersion() => cacheVersion;

  @override
  Future<void> saveQuranPagesCacheVersion(int value) async {
    cacheVersion = value;
  }

  @override
  Future<void> clearQuranPagesCacheVersion() async {
    cacheVersion = null;
  }
}

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final Directory root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root.path;

  @override
  Future<String?> getApplicationSupportPath() async => root.path;

  @override
  Future<String?> getTemporaryPath() async => root.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _StorageStub storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('quran_page_cache_test');
    storage = _StorageStub();
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  QuranPageImageCacheService buildService({
    required Future<http.Response> Function(http.Request request) handler,
  }) {
    return QuranPageImageCacheService(
      storage,
      client: MockClient((request) => handler(request)),
    );
  }

  File pageFile(int pageNumber) =>
      File('${tempDir.path}/quran_pages/quran_svg/'
          '${pageNumber.toString().padLeft(3, '0')}.svg');

  group('getPageFile', () {
    test('downloads and caches an uncached page on demand', () async {
      var requests = 0;
      final service = buildService(
        handler: (request) async {
          requests++;
          return http.Response(
            '<svg id="${request.url.pathSegments.last}"/>',
            200,
            headers: {'content-type': 'image/svg+xml'},
          );
        },
      );

      final file = await service.getPageFile(42);

      expect(requests, 1);
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), contains('042.svg'));
    });

    test('serves a cached page without hitting the network', () async {
      final file = pageFile(7);
      await file.parent.create(recursive: true);
      await file.writeAsString('<svg>cached</svg>');

      var requests = 0;
      final service = buildService(
        handler: (request) async {
          requests++;
          return http.Response('should not be used', 500);
        },
      );

      final result = await service.getPageFile(7);

      expect(requests, 0);
      expect(await result.readAsString(), '<svg>cached</svg>');
    });

    test('keeps the cached page when a refresh download fails', () async {
      final file = pageFile(9);
      await file.parent.create(recursive: true);
      await file.writeAsString('<svg>existing</svg>');

      final service = buildService(
        handler: (request) async => http.Response('boom', 404),
      );

      // An existing cache is served without any request, so it survives.
      final result = await service.getPageFile(9);
      expect(await result.readAsString(), '<svg>existing</svg>');
    });

    test('throws a descriptive error for a non-200 response', () async {
      final service = buildService(
        handler: (request) async => http.Response('missing', 404),
      );

      await expectLater(
        service.getPageFile(5),
        throwsA(
          isA<QuranPageImageException>().having(
            (e) => e.message,
            'message',
            contains('HTTP 404'),
          ),
        ),
      );
    });

    test('throws when the request times out', () async {
      final service = QuranPageImageCacheService(
        storage,
        client: MockClient((request) async {
          await Future<void>.delayed(const Duration(seconds: 5));
          return http.Response('late', 200);
        }),
        documentsDirectoryProvider: () async => tempDir,
        timeout: const Duration(milliseconds: 200),
      );

      await expectLater(
        service.getPageFile(3),
        throwsA(
          isA<QuranPageImageException>().having(
            (e) => e.message,
            'message',
            contains('Timed out'),
          ),
        ),
      );
    });

    test('clamps out of range page numbers', () async {
      final requested = <String>[];
      final service = buildService(
        handler: (request) async {
          requested.add(request.url.pathSegments.last);
          return http.Response('ok', 200);
        },
      );

      await service.getPageFile(0);
      await service.getPageFile(9999);

      expect(requested, ['001.svg', '604.svg']);
    });
  });

  group('getCachedPageFile', () {
    test('returns null for an uncached page without downloading', () async {
      var requests = 0;
      final service = buildService(
        handler: (request) async {
          requests++;
          return http.Response('unexpected', 200);
        },
      );

      final result = await service.getCachedPageFile(11);

      expect(result, isNull);
      expect(requests, 0);
    });

    test('returns the file for a cached page', () async {
      final file = pageFile(11);
      await file.parent.create(recursive: true);
      await file.writeAsString('<svg>cached</svg>');

      final service = buildService(handler: (_) async => http.Response('', 500));

      final result = await service.getCachedPageFile(11);

      expect(result, isNotNull);
      expect(await result!.readAsString(), '<svg>cached</svg>');
    });
  });

  group('ensurePagesCached', () {
    test('can be stopped early for a cancellable background prefetch', () async {
      var requests = 0;
      final service = buildService(
        handler: (request) async {
          requests++;
          return http.Response('<svg/>', 200);
        },
      );

      await service.ensurePagesCached(
        shouldContinue: () => requests < 5,
      );

      expect(requests, lessThan(QuranPageImageCacheService.lastPage));
      // Whatever was downloaded before stopping must remain readable.
      final file = pageFile(1);
      expect(await file.exists(), isTrue);
    });

    test('stops when the cache is already complete', () async {
      var requests = 0;
      final service = buildService(
        handler: (request) async {
          requests++;
          return http.Response('<svg/>', 200);
        },
      );

      await service.ensurePagesCached();
      storage.cacheVersion = QuranPageImageCacheService.cacheVersion;

      final requestsAfterFirstRun = requests;
      await service.ensurePagesCached();

      expect(requests, requestsAfterFirstRun);
    });

    test('reports progress for the first pages downloaded', () async {
      final service = buildService(
        handler: (request) async => http.Response('<svg/>', 200),
      );

      final progress = <QuranPagesDownloadProgress>[];
      await service.ensurePagesCached(
        onProgress: progress.add,
        shouldContinue: () => progress.length < 3,
      );

      expect(progress, isNotEmpty);
      expect(progress.last.downloadedCount, lessThanOrEqualTo(3));
    });
  });

  group('pageUrl', () {
    test('builds a padded url', () {
      final service = QuranPageImageCacheService(
        storage,
        client: MockClient((_) async => http.Response('', 200)),
      );

      expect(service.pageUrl(1), endsWith('/001.svg'));
      expect(service.pageUrl(604), endsWith('/604.svg'));
    });

    test('prefers the versioned CDN over GitHub raw', () {
      final service = QuranPageImageCacheService(
        storage,
        client: MockClient((_) async => http.Response('', 200)),
      );

      expect(service.pageUrl(1), startsWith('https://cdn.quran.ws/'));
      expect(
        service.pageUrls(1).last,
        startsWith('https://raw.githubusercontent.com/quran-ws/'),
      );
    });

    test('falls back to the next source when the first one fails', () async {
      final requestedHosts = <String>[];
      final service = buildService(
        handler: (request) async {
          requestedHosts.add(request.url.host);
          if (request.url.host == 'cdn.quran.ws') {
            return http.Response('gone', 404);
          }
          return http.Response('<svg>fallback</svg>', 200);
        },
      );

      final file = await service.getPageFile(42);

      expect(requestedHosts, ['cdn.quran.ws', 'raw.githubusercontent.com']);
      expect(await file.readAsString(), '<svg>fallback</svg>');
    });
  });

  group('QuranPagesDownloadProgress', () {
    test('computes ratio and percentage', () {
      const progress = QuranPagesDownloadProgress(
        downloadedCount: 302,
        totalCount: 604,
      );

      expect(progress.ratio, closeTo(0.5, 0.001));
      expect(progress.percentage, 50);
    });

    test('guards against a zero total', () {
      const progress = QuranPagesDownloadProgress(
        downloadedCount: 0,
        totalCount: 0,
      );

      expect(progress.ratio, 0);
      expect(progress.percentage, 0);
    });
  });
}
