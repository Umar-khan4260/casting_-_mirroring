import 'package:flutter/foundation.dart';

enum CastLogLevel { debug, info, warning, error }

class CastLogger {
  final String _tag;
  static CastLogLevel _minLevel = CastLogLevel.debug;

  const CastLogger(this._tag);

  static void setMinLevel(CastLogLevel level) => _minLevel = level;

  void debug(String message) => _log(CastLogLevel.debug, message);
  void info(String message) => _log(CastLogLevel.info, message);
  void warning(String message) => _log(CastLogLevel.warning, message);
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(CastLogLevel.error, message);
    if (error != null) {
      debugPrint('  [$error]');
    }
    if (stackTrace != null && _minLevel.index <= CastLogLevel.debug.index) {
      debugPrint('  $stackTrace');
    }
  }

  void _log(CastLogLevel level, String message) {
    if (level.index < _minLevel.index) return;
    if (!kDebugMode) return;
    final prefix = level.name.toUpperCase().padRight(7);
    debugPrint('[$prefix] $_tag: $message');
  }
}
