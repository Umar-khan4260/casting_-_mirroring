import 'dart:async';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../utils/cast_logger.dart';

const _log = CastLogger('LocalMediaServer');

class LocalMediaServer {
  HttpServer? _server;
  String? _currentFilePath;
  String? _currentToken;
  String? _lanIpAddress;
  int? _port;
  bool _isServing = false;

  bool get isServing => _isServing;
  String? get currentUrl => _lanIpAddress != null && _port != null && _currentToken != null
      ? 'http://$_lanIpAddress:$_port/media/$_currentToken'
      : null;
  int? get port => _port;
  String? get lanIp => _lanIpAddress;

  Future<String?> start(String filePath) async {
    if (_isServing) {
      await stop();
    }

    _currentFilePath = filePath;
    _currentToken = _generateToken();

    final file = File(filePath);
    if (!await file.exists()) {
      _log.error('File does not exist: $filePath');
      return null;
    }

    _lanIpAddress = await _getLanIpAddress();
    if (_lanIpAddress == null) {
      _log.error('Could not determine LAN IP address');
      return null;
    }

    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_handleRequest);

    try {
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        0,
      );
      _port = _server!.port;
      _isServing = true;
      final url = currentUrl;
      _log.info('Server started on $url');
      return url;
    } catch (e) {
      _log.error('Failed to start server', e);
      await stop();
      return null;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _isServing = false;
    _currentFilePath = null;
    _currentToken = null;
    _port = null;
    _lanIpAddress = null;
    _log.info('Server stopped');
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    final path = request.url.path;

    if (path == 'media/$_currentToken') {
      return _serveMedia(request);
    }

    return shelf.Response.notFound('Not found');
  }

  Future<shelf.Response> _serveMedia(shelf.Request request) async {
    if (_currentFilePath == null) {
      return shelf.Response.internalServerError(body: 'No media loaded');
    }

    final file = File(_currentFilePath!);
    if (!await file.exists()) {
      return shelf.Response.notFound('Media file not found');
    }

    final fileLength = await file.length();
    final mimeType = lookupMimeType(_currentFilePath!) ?? 'application/octet-stream';

    final rangeHeader = request.headers['range'];

    if (rangeHeader != null) {
      return _handleRangeRequest(request, file, fileLength, mimeType, rangeHeader);
    }

    return shelf.Response.ok(
      file.openRead(),
      headers: {
        'Content-Type': mimeType,
        'Content-Length': fileLength.toString(),
        'Accept-Ranges': 'bytes',
        'Access-Control-Allow-Origin': '*',
      },
    );
  }

  shelf.Response _handleRangeRequest(
    shelf.Request request,
    File file,
    int fileLength,
    String mimeType,
    String rangeHeader,
  ) {
    final range = _parseRangeHeader(rangeHeader, fileLength);
    if (range == null) {
      return shelf.Response(
        416,
        body: 'Range Not Satisfiable',
        headers: {
          'Content-Range': 'bytes */$fileLength',
        },
      );
    }

    final start = range[0];
    final end = range[1];
    final contentLength = end - start + 1;

    return shelf.Response(
      206,
      body: file.openRead(start, end + 1),
      headers: {
        'Content-Type': mimeType,
        'Content-Length': contentLength.toString(),
        'Content-Range': 'bytes $start-$end/$fileLength',
        'Accept-Ranges': 'bytes',
        'Access-Control-Allow-Origin': '*',
      },
    );
  }

  List<int>? _parseRangeHeader(String rangeHeader, int fileLength) {
    if (!rangeHeader.startsWith('bytes=')) return null;

    final rangeValue = rangeHeader.substring(6);
    final parts = rangeValue.split('-');
    if (parts.length != 2) return null;

    int start;
    int end;

    if (parts[0].isEmpty) {
      start = fileLength - int.parse(parts[1]);
      end = fileLength - 1;
    } else if (parts[1].isEmpty) {
      start = int.parse(parts[0]);
      end = fileLength - 1;
    } else {
      start = int.parse(parts[0]);
      end = int.parse(parts[1]);
    }

    if (start < 0 || end >= fileLength || start > end) return null;

    return [start, end];
  }

  String _generateToken() {
    final random = List<int>.generate(16, (_) => _secureRandom());
    return random.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  int _secureRandom() {
    final random = DateTime.now().microsecondsSinceEpoch;
    return (random ^ (random >> 8)) & 0xFF;
  }

  Future<String?> _getLanIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        if (interface.name == 'lo' || interface.name == 'lo0') continue;

        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            _log.debug('Found LAN IP: ${addr.address} on ${interface.name}');
            return addr.address;
          }
        }
      }

      _log.warning('No suitable LAN interface found');
      return null;
    } catch (e) {
      _log.error('Failed to get LAN IP', e);
      return null;
    }
  }
}
