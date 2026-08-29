import '../../models/cast_device.dart';

/// Describes the current state of screen mirroring.
enum MirroringState {
  /// No mirroring active, no AirPlay route selected.
  idle,

  /// AirPlay route is available and media can be routed.
  airPlayAvailable,

  /// Media is being routed via AirPlay to an external display.
  airPlayConnected,

  /// System-level screen mirroring is active (detected, not controlled by us).
  systemMirroringActive,

  /// An error occurred.
  error,
}

/// Abstract interface for screen mirroring functionality.
///
/// On iOS, true full-device screen mirroring (mirror the entire iPhone screen
/// including home screen, other apps, and system UI) can only be initiated by
/// the user via Control Center → Screen Mirroring. Third-party apps cannot
/// programmatically trigger this.
///
/// What this interface supports:
/// - Detecting AirPlay route availability
/// - Presenting the system AirPlay route picker (AVRoutePickerView)
/// - Detecting when system-level screen mirroring is active
/// - Routing AVPlayer media content to AirPlay receivers
///
/// Limitations documented at: lib/screen_mirroring/PLATFORM_LIMITATIONS.md
abstract class ScreenMirroringInterface {
  /// Stream of discovered devices that support screen mirroring / AirPlay.
  Stream<List<CastDevice>> get discoveredDevices;

  /// Current mirroring state.
  MirroringState get mirroringState;

  /// The currently connected AirPlay route name, if any.
  String? get connectedRouteName;

  /// Whether AirPlay is available on this device.
  bool get isAirPlayAvailable;

  /// Starts monitoring AirPlay route changes and mirroring state.
  Future<void> startMonitoring();

  /// Stops monitoring AirPlay route changes.
  Future<void> stopMonitoring();

  /// Presents the system AirPlay route picker.
  ///
  /// On iOS, this shows the standard AVRoutePickerView popover where the user
  /// can select an AirPlay receiver for media routing.
  ///
  /// This does NOT start full-device screen mirroring — that requires the user
  /// to go to Control Center → Screen Mirroring.
  Future<void> showRoutePicker();

  /// Routes media content to the specified AirPlay device.
  ///
  /// This is for AVPlayer-based content routing, not full screen mirroring.
  Future<void> routeMediaTo(CastDevice device);

  /// Stops routing media to AirPlay.
  Future<void> stopRouting();
}
