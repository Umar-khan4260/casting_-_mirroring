import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/services/local_media_server.dart';

void main() {
  late LocalMediaServer server;
  late Directory tempDir;
  late File testFile;

  setUp(() async {
    server = LocalMediaServer();
    tempDir = await Directory.systemTemp.createTemp('media_server_test_');
    testFile = File('${tempDir.path}${Platform.pathSeparator}test_video.mp4');
    await testFile.writeAsBytes(List<int>.filled(1024, 42));
  });

  tearDown(() async {
    await server.stop();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalMediaServer', () {
    test('initially not serving', () {
      expect(server.isServing, false);
      expect(server.currentUrl, isNull);
      expect(server.port, isNull);
      expect(server.lanIp, isNull);
    });

    test('starts and returns URL', () async {
      final url = await server.start(testFile.path);

      expect(url, isNotNull);
      expect(url, startsWith('http://'));
      expect(server.isServing, true);
      expect(server.port, isNotNull);
      expect(server.lanIp, isNotNull);
      expect(server.currentUrl, url);
    });

    test('URL contains random token', () async {
      final url = await server.start(testFile.path);

      expect(url, isNotNull);
      final uri = Uri.parse(url!);
      expect(uri.pathSegments.length, greaterThanOrEqualTo(2));
      expect(uri.pathSegments[0], 'media');
      final token = uri.pathSegments[1];
      expect(token.length, 32);
    });

    test('serves media file', () async {
      final url = await server.start(testFile.path);
      expect(url, isNotNull);

      final uri = Uri.parse(url!);
      final localUrl = 'http://127.0.0.1:${uri.port}${uri.path}';
      final response = await HttpClient().getUrl(Uri.parse(localUrl));
      final httpResponse = await response.close();

      expect(httpResponse.statusCode, 200);
      expect(
        httpResponse.headers.value('content-type'),
        'video/mp4',
      );
      expect(
        httpResponse.headers.value('content-length'),
        '1024',
      );
      expect(
        httpResponse.headers.value('accept-ranges'),
        'bytes',
      );
    });

    test('handles Range requests', () async {
      final url = await server.start(testFile.path);
      expect(url, isNotNull);

      final uri = Uri.parse(url!);
      final localUrl = 'http://127.0.0.1:${uri.port}${uri.path}';
      final request = await HttpClient().getUrl(Uri.parse(localUrl));
      request.headers.set('Range', 'bytes=0-100');
      final response = await request.close();

      expect(response.statusCode, 206);
      expect(
        response.headers.value('content-range'),
        startsWith('bytes 0-100/1024'),
      );
      expect(
        response.headers.value('content-length'),
        '101',
      );
    });

    test('handles Range request from end', () async {
      final url = await server.start(testFile.path);
      expect(url, isNotNull);

      final uri = Uri.parse(url!);
      final localUrl = 'http://127.0.0.1:${uri.port}${uri.path}';
      final request = await HttpClient().getUrl(Uri.parse(localUrl));
      request.headers.set('Range', 'bytes=-100');
      final response = await request.close();

      expect(response.statusCode, 206);
      expect(
        response.headers.value('content-range'),
        startsWith('bytes 924-1023/1024'),
      );
      expect(
        response.headers.value('content-length'),
        '100',
      );
    });

    test('returns 416 for invalid range', () async {
      final url = await server.start(testFile.path);
      expect(url, isNotNull);

      final uri = Uri.parse(url!);
      final localUrl = 'http://127.0.0.1:${uri.port}${uri.path}';
      final request = await HttpClient().getUrl(Uri.parse(localUrl));
      request.headers.set('Range', 'bytes=2000-3000');
      final response = await request.close();

      expect(response.statusCode, 416);
    });

    test('returns 404 for unknown path', () async {
      final url = await server.start(testFile.path);
      expect(url, isNotNull);

      final uri = Uri.parse(url!);
      final badUrl = 'http://127.0.0.1:${uri.port}/unknown/path';
      final response = await HttpClient().getUrl(Uri.parse(badUrl));
      final httpResponse = await response.close();

      expect(httpResponse.statusCode, 404);
    });

    test('stops server', () async {
      await server.start(testFile.path);
      expect(server.isServing, true);

      await server.stop();
      expect(server.isServing, false);
      expect(server.currentUrl, isNull);
      expect(server.port, isNull);
      expect(server.lanIp, isNull);
    });

    test('replaces previous server on restart', () async {
      final url1 = await server.start(testFile.path);
      expect(url1, isNotNull);

      final url2 = await server.start(testFile.path);
      expect(url2, isNotNull);
      expect(url2, isNot(equals(url1)));
      expect(server.isServing, true);
    });

    test('returns null for nonexistent file', () async {
      final url = await server.start('/nonexistent/file.mp4');
      expect(url, isNull);
      expect(server.isServing, false);
    });

    test('generates different tokens for different starts', () async {
      final url1 = await server.start(testFile.path);
      await server.stop();
      final url2 = await server.start(testFile.path);

      expect(url1, isNotNull);
      expect(url2, isNotNull);

      final token1 = Uri.parse(url1!).pathSegments[1];
      final token2 = Uri.parse(url2!).pathSegments[1];
      expect(token1, isNot(equals(token2)));
    });

    test('CORS headers are set', () async {
      final url = await server.start(testFile.path);
      expect(url, isNotNull);

      final uri = Uri.parse(url!);
      final localUrl = 'http://127.0.0.1:${uri.port}${uri.path}';
      final response = await HttpClient().getUrl(Uri.parse(localUrl));
      final httpResponse = await response.close();

      expect(
        httpResponse.headers.value('access-control-allow-origin'),
        '*',
      );
    });
  });
}
