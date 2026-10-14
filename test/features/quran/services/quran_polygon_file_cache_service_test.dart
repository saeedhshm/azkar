import 'dart:convert';
import 'dart:io';

import 'package:azkar/core/storage/local_storage_service.dart';
import 'package:azkar/features/quran/services/quran_polygon_file_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _StorageStub extends LocalStorageService {
  int? cacheVersion;

  @override
  int? getQuranPolygonCacheVersion() => cacheVersion;

  @override
  Future<void> saveQuranPolygonCacheVersion(int value) async {
    cacheVersion = value;
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
    tempDir = await Directory.systemTemp.createTemp('polygon_cache_test');
    storage = _StorageStub();
    storage.cacheVersion = QuranPolygonFileCacheService.cacheVersion;
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<QuranPolygonFileCacheService> buildService({
    required Future<http.Response> Function(http.Request request) handler,
    Duration? timeout,
  }) {
    return Future.value(
      QuranPolygonFileCacheService(
        storage,
        client: MockClient((request) => handler(request)),
        timeout: timeout,
      ),
    );
  }

  test('fetches and caches polygon data', () async {
    var requests = 0;
    final service = await buildService(
      handler: (request) async {
        requests++;
        return http.Response('{"polygons": []}', 200);
      },
    );

    final json = await service.getPageJson(3);

    expect(requests, 1);
    expect(jsonDecode(json), {'polygons': []});
  });

  test('serves a cached polygon page without a request', () async {
    final file = File('${tempDir.path}/quran_pages/hafs_polygon_json/003.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('{"cached": true}');

    var requests = 0;
    final service = await buildService(
      handler: (request) async {
        requests++;
        return http.Response('{}', 500);
      },
    );

    final json = await service.getPageJson(3);

    expect(requests, 0);
    expect(jsonDecode(json), {'cached': true});
  });

  test('throws a descriptive error for a failed request', () async {
    final service = await buildService(
      handler: (request) async => http.Response('missing', 404),
    );

    await expectLater(
      service.getPageJson(5),
      throwsA(
        isA<QuranPolygonException>().having(
          (e) => e.message,
          'message',
          contains('HTTP 404'),
        ),
      ),
    );
  });

  test('a stalled request fails within the timeout', () async {
    final service = await buildService(
      handler: (request) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return http.Response('late', 200);
      },
      timeout: const Duration(milliseconds: 200),
    );

    await expectLater(
      service.getPageJson(9),
      throwsA(
        isA<QuranPolygonException>().having(
          (e) => e.message,
          'message',
          contains('Timed out'),
        ),
      ),
    );
  });

  test('prefetch failures are swallowed so reading is never interrupted', () async {
    final service = await buildService(
      handler: (request) async => http.Response('missing', 404),
    );

    await expectLater(service.prefetchPage(12), completes);
  });

  test('clamps out of range page numbers', () async {
    final requested = <String>[];
    final service = await buildService(
      handler: (request) async {
        requested.add(request.url.pathSegments.last);
        return http.Response('{}', 200);
      },
    );

    await service.getPageJson(0);
    await service.getPageJson(9999);

    expect(requested, ['001.json', '604.json']);
  });

  test('falls back to the next source when the first one fails', () async {
    final requestedHosts = <String>[];
    final service = await buildService(
      handler: (request) async {
        requestedHosts.add(request.url.host);
        if (request.url.host == 'cdn.quran.ws') {
          return http.Response('gone', 404);
        }
        return http.Response('{"fallback": true}', 200);
      },
    );

    final json = await service.getPageJson(21);

    expect(requestedHosts, ['cdn.quran.ws', 'raw.githubusercontent.com']);
    expect(jsonDecode(json), {'fallback': true});
  });
}
