import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/cast_logger.dart';

const _log = CastLogger('AirPlayChannel');

enum AirPlayConnectionState {
  disconnected,
  connected,
  systemMirroringActive,
  error,
}

class AirPlayRoute {
  final String name;
  final bool isActive;
  final AirPlayConnectionState state;

  const AirPlayRoute({
    required this.name,
    this.isActive = false,
    this.state = AirPlayConnectionState.disconnected,
  });

  factory AirPlayRoute.fromMap(Map<dynamic, dynamic> map) {
    return AirPlayRoute(
      name: map['currentRouteName'] as String? ?? 'Unknown',
      isActive: map['isAirPlayActive'] as bool? ?? false,
      state: map['isSystemMirroringActive'] as bool
          ? AirPlayConnectionState.systemMirroringActive
          : map['isAirPlayActive'] as bool
              ? AirPlayConnectionState.connected
              : AirPlayConnectionState.disconnected,
    );
  }
}

class AirPlayChannel {
  static const MethodChannel _methodChannel =
      MethodChannel('com.casting_mirroring/airplay');
  static const EventChannel _eventChannel =
      EventChannel('com.casting_mirroring/airplay_events');

  StreamSubscription<dynamic>? _eventSubscription;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;

  Future<bool> isAirPlayAvailable() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>('getAirPlayAvailability');
      return result?['isAvailable'] as bool? ?? false;
    } on PlatformException catch (e) {
      _log.warning('isAirPlayAvailable failed: ${e.message}');
      return false;
    }
  }

  Future<Map<String, dynamic>> getMirroringStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>('getMirroringStatus');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      _log.error('getMirroringStatus failed: ${e.message}');
      return {
        'isSystemMirroringActive': false,
        'isAirPlayConnected': false,
        'error': e.message,
      };
    }
  }

  Future<Map<String, dynamic>> showRoutePicker() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>('showRoutePicker');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      _log.error('showRoutePicker failed: ${e.message}');
      return {
        'success': false,
        'message': e.message ?? 'Failed to show route picker',
      };
    }
  }

  Future<void> startMonitoring() async {
    try {
      await _methodChannel.invokeMethod('startMonitoring');
      _eventSubscription?.cancel();
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is Map) {
            _eventController.add(Map<String, dynamic>.from(event));
          }
        },
        onError: (e) {
          _log.error('Event stream error', e);
        },
      );
      _log.info('Monitoring started');
    } on PlatformException catch (e) {
      _log.error('startMonitoring failed: ${e.message}');
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      await _methodChannel.invokeMethod('stopMonitoring');
      _log.info('Monitoring stopped');
    } on PlatformException catch (e) {
      _log.error('stopMonitoring failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> openControlCenterMirror() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>('openControlCenterMirror');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      _log.error('openControlCenterMirror failed: ${e.message}');
      return {
        'success': false,
        'message': e.message ?? 'Cannot programmatically start screen mirroring',
      };
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventController.close();
    _log.info('Disposed');
  }
}
