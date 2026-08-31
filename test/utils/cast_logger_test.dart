import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/utils/cast_logger.dart';

void main() {
  group('CastLogger', () {
    test('can be instantiated with a tag', () {
      const logger = CastLogger('TestTag');
      // Should not throw
      logger.debug('debug message');
      logger.info('info message');
      logger.warning('warning message');
      logger.error('error message');
    });

    test('setMinLevel does not throw', () {
      CastLogger.setMinLevel(CastLogLevel.error);
      CastLogger.setMinLevel(CastLogLevel.debug);
    });

    test('error method accepts optional error and stackTrace', () {
      const logger = CastLogger('Test');
      logger.error(
        'Something failed',
        Exception('test exception'),
        StackTrace.current,
      );
      // Should not throw
    });

    test('error method works without optional params', () {
      const logger = CastLogger('Test');
      logger.error('Simple error');
    });

    test('multiple loggers with different tags', () {
      const logger1 = CastLogger('Tag1');
      const logger2 = CastLogger('Tag2');
      // Both should work independently
      logger1.info('Message from logger1');
      logger2.info('Message from logger2');
    });
  });
}
