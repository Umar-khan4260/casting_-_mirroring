import 'dart:async';
import '../models/cast_device.dart';
import '../casting_core/interfaces/screen_mirroring_interface.dart';
import 'air_play_channel.dart';

/// Manages screen mirroring via AirPlay on iOS.
///
/// ## iOS Platform Limitation
///
/// **Third-party apps CANNOT programmatically initiate full-device AirPlay mirroring.**
/// The user must manually go to Control Center → Screen Mirroring to mirror
/// the entire iPhone screen.
///
/// This manager provides:
/// - AirPlay route availability detection
/// - System AirPlay route picker presentation
/// - Detection of active AirPlay/screen mirroring sessions
///
/// It does NOT provide programmatic full-device mirroring because iOS
/// does not allow it. This is documented, not faked.
class ScreenMirrorManager implements ScreenMirroringInterface {
  final AirPlayChannel _airPlayChannel = AirPlayChannel();

  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();

  MirroringState _mirroringState = MirroringState.idle;
  String? _connectedRouteName;
  bool _isAirPlayAvailable = false;
  bool _isMonitoring = false;

  @override
  Stream<List<CastDevice>> get discoveredDevices => _devicesController.stream;

  @override
  MirroringState get mirroringState => _mirroringState;

  @override
  String? get connectedRouteName => _connectedRouteName;

  @override
  bool get isAirPlayAvailable => _isAirPlayAvailable;

  @override
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    _isAirPlayAvailable = await _airPlayChannel.isAirPlayAvailable();

    await _airPlayChannel.startMonitoring();

    // Listen for native events
    _airPlayChannel.events.listen((event) {
      _handleNativeEvent(event);
    });

    // Get initial status
    final status = await _airPlayChannel.getMirroringStatus();
    _updateFromStatus(status);
  }

  @override
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;
    _isMonitoring = false;

    await _airPlayChannel.stopMonitoring();
  }

  @override
  Future<void> showRoutePicker() async {
    await _airPlayChannel.showRoutePicker();

    // Refresh status after picker is dismissed
    await Future.delayed(const Duration(milliseconds: 500));
    final status = await _airPlayChannel.getMirroringStatus();
    _updateFromStatus(status);
  }

  @override
  Future<void> routeMediaTo(CastDevice device) async {
    // On iOS, media routing to AirPlay is handled by the system route picker
    // or by setting AVPlayer.allowsExternalPlayback = true.
    // We present the route picker as the user-facing mechanism.
    await showRoutePicker();
  }

  @override
  Future<void> stopRouting() async {
    _mirroringState = MirroringState.idle;
    _connectedRouteName = null;
  }

  void _handleNativeEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'routeChange':
      case 'routePickerClosed':
      case 'initialState':
        _updateFromStatus(data);
        break;
      case 'systemMirroringStarted':
        _mirroringState = MirroringState.systemMirroringActive;
        _connectedRouteName = data['connectedDeviceName'] as String?;
        _emitDevices();
        break;
      case 'systemMirroringStopped':
        _mirroringState = MirroringState.idle;
        _connectedRouteName = null;
        _emitDevices();
        break;
    }
  }

  void _updateFromStatus(Map<String, dynamic> status) {
    final isSystemMirroring =
        status['isSystemMirroringActive'] as bool? ?? false;
    final isAirPlayConnected = status['isAirPlayConnected'] as bool? ?? false;
    final deviceName = status['connectedDeviceName'] as String?;

    if (isSystemMirroring) {
      _mirroringState = MirroringState.systemMirroringActive;
      _connectedRouteName =
          status['mirroredScreenName'] as String? ?? deviceName;
    } else if (isAirPlayConnected) {
      _mirroringState = MirroringState.airPlayConnected;
      _connectedRouteName = deviceName;
    } else if (_isAirPlayAvailable) {
      _mirroringState = MirroringState.airPlayAvailable;
      _connectedRouteName = null;
    } else {
      _mirroringState = MirroringState.idle;
      _connectedRouteName = null;
    }

    _emitDevices();
  }

  void _emitDevices() {
    if (_mirroringState == MirroringState.idle) {
      _devicesController.add([]);
      return;
    }

    final isConnected =
        _mirroringState == MirroringState.airPlayConnected ||
        _mirroringState == MirroringState.systemMirroringActive;

    _devicesController.add([
      CastDevice(
        id: 'airplay_system',
        name: _connectedRouteName ?? 'AirPlay',
        type: DeviceType.appleAirPlay,
        connectionState: DeviceConnectionState.disconnected,
        mirroringConnectionState: isConnected
            ? DeviceConnectionState.connected
            : DeviceConnectionState.disconnected,
        supportsMediaCasting: false,
        supportsScreenMirroring: true,
      ),
    ]);
  }

  void dispose() {
    _devicesController.close();
    _airPlayChannel.dispose();
  }
}
