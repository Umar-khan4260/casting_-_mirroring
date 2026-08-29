import 'dart:async';
import 'package:flutter/services.dart';

/// Describes the current state of the AirPlay connection.
enum AirPlayConnectionState {
  /// No AirPlay route selected.
  disconnected,

  /// AirPlay route is available and selected.
  connected,

  /// System-level screen mirroring is active (detected, not controlled by us).
  systemMirroringActive,

  /// An error occurred.
  error,
}

/// Represents an AirPlay route/device.
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

/// Flutter ↔ native communication layer for AirPlay screen mirroring.
///
/// This class communicates with the native iOS AirPlayPlugin via method channels.
///
/// IMPORTANT iOS PLATFORM LIMITATION:
/// Third-party apps CANNOT programmatically initiate full-device AirPlay
/// mirroring. The user must manually go to Control Center → Screen Mirroring.
/// This plugin can only:
/// - Detect AirPlay route availability
/// - Show the system AirPlay route picker (for media routing)
/// - Detect when system-level mirroring is active
class AirPlayChannel {
  static const MethodChannel _methodChannel =
      MethodChannel('com.casting_mirroring/airplay');
  static const EventChannel _eventChannel =
      EventChannel('com.casting_mirroring/airplay_events');

  StreamSubscription<dynamic>? _eventSubscription;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of AirPlay events from the native side.
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  /// Check if AirPlay is available on this device.
  Future<bool> isAirPlayAvailable() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>('getAirPlayAvailability');
      return result?['isAvailable'] as bool? ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get the current mirroring/connection status.
  Future<Map<String, dynamic>> getMirroringStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>('getMirroringStatus');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      return {
        'isSystemMirroringActive': false,
        'isAirPlayConnected': false,
        'error': e.message,
      };
    }
  }

  /// Show the system AirPlay route picker.
  ///
  /// This presents the standard iOS AVRoutePickerView where the user can
  /// select an AirPlay receiver for media routing.
  ///
  /// Returns a map with 'success' and 'message' keys.
  Future<Map<String, dynamic>> showRoutePicker() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>('showRoutePicker');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Failed to show route picker',
      };
    }
  }

  /// Start monitoring AirPlay route changes and mirroring state.
  Future<void> startMonitoring() async {
    try {
      await _methodChannel.invokeMethod('startMonitoring');
      _eventSubscription?.cancel();
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
        if (event is Map) {
          _eventController.add(Map<String, dynamic>.from(event));
        }
      });
    } on PlatformException catch (_) {
      // Silently fail - monitoring is best-effort
    }
  }

  /// Stop monitoring AirPlay route changes.
  Future<void> stopMonitoring() async {
    try {
      await _eventSubscription?.cancel();
      _eventSubscription = null;
      await _methodChannel.invokeMethod('stopMonitoring');
    } on PlatformException catch (_) {
      // Silently fail
    }
  }

  /// Attempt to open Control Center's Screen Mirroring.
  ///
  /// This will always return success=false because iOS does not allow
  /// third-party apps to programmatically open Control Center's Screen
  /// Mirroring section. The returned message explains this limitation.
  Future<Map<String, dynamic>> openControlCenterMirror() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>('openControlCenterMirror');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Cannot programmatically start screen mirroring',
      };
    }
  }

  /// Dispose resources.
  void dispose() {
    _eventSubscription?.cancel();
    _eventController.close();
  }
}
