import 'dart:async';
import '../models/cast_device.dart';
import '../casting_core/interfaces/screen_mirroring_interface.dart';
import 'air_play_channel.dart';
import '../utils/cast_logger.dart';

const _log = CastLogger('ScreenMirror');

class ScreenMirrorManager implements ScreenMirroringInterface {
  final AirPlayChannel _airPlayChannel = AirPlayChannel();

  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();

  MirroringState _mirroringState = MirroringState.idle;
  String? _connectedRouteName;
  bool _isAirPlayAvailable = false;
  bool _isMonitoring = false;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

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

    try {
      _isAirPlayAvailable = await _airPlayChannel.isAirPlayAvailable();
      _log.info('AirPlay available: $_isAirPlayAvailable');
    } catch (e) {
      _log.error('Failed to check AirPlay availability', e);
      _isAirPlayAvailable = false;
    }

    try {
      await _airPlayChannel.startMonitoring();
    } catch (e) {
      _log.error('Failed to start AirPlay monitoring', e);
      _mirroringState = MirroringState.error;
      _emitDevices();
      return;
    }

    _eventSubscription?.cancel();
    _eventSubscription = _airPlayChannel.events.listen(
      _handleNativeEvent,
      onError: (e) {
        _log.error('AirPlay event stream error', e);
      },
    );

    try {
      final status = await _airPlayChannel.getMirroringStatus();
      _updateFromStatus(status);
    } catch (e) {
      _log.error('Failed to get initial AirPlay status', e);
    }
  }

  @override
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;
    _isMonitoring = false;

    await _eventSubscription?.cancel();
    _eventSubscription = null;

    try {
      await _airPlayChannel.stopMonitoring();
    } catch (e) {
      _log.error('Failed to stop AirPlay monitoring', e);
    }
  }

  @override
  Future<void> showRoutePicker() async {
    try {
      await _airPlayChannel.showRoutePicker();
    } catch (e) {
      _log.error('Failed to show route picker', e);
      _mirroringState = MirroringState.error;
      _emitDevices();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final status = await _airPlayChannel.getMirroringStatus();
      _updateFromStatus(status);
    } catch (e) {
      _log.error('Failed to refresh status after route picker', e);
    }
  }

  @override
  Future<void> routeMediaTo(CastDevice device) async {
    await showRoutePicker();
  }

  @override
  Future<void> stopRouting() async {
    _mirroringState = MirroringState.idle;
    _connectedRouteName = null;
    _emitDevices();
    _log.info('Routing stopped');
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
        _log.info('System mirroring started: $_connectedRouteName');
        _emitDevices();
        break;
      case 'systemMirroringStopped':
        _mirroringState = MirroringState.idle;
        _connectedRouteName = null;
        _log.info('System mirroring stopped');
        _emitDevices();
        break;
      default:
        _log.debug('Unknown native event: $type');
    }
  }

  void _updateFromStatus(Map<String, dynamic> status) {
    final isSystemMirroring =
        status['isSystemMirroringActive'] as bool? ?? false;
    final isAirPlayConnected = status['isAirPlayConnected'] as bool? ?? false;
    final deviceName = status['connectedDeviceName'] as String?;

    final previousState = _mirroringState;

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

    if (previousState != _mirroringState) {
      _log.debug('State: $previousState -> $_mirroringState');
    }

    _emitDevices();
  }

  void _emitDevices() {
    if (_mirroringState == MirroringState.idle ||
        _mirroringState == MirroringState.error) {
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
    _eventSubscription?.cancel();
    _devicesController.close();
    _airPlayChannel.dispose();
    _log.info('Disposed');
  }
}
