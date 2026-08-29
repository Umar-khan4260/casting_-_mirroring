import 'dart:async';
import '../models/cast_device.dart';
import 'device_discovery_service.dart';
import '../casting_core/casting_manager.dart';
import '../utils/cast_logger.dart';

const _log = CastLogger('DiscoveryService');

class RealDeviceDiscoveryService implements DeviceDiscoveryService {
  final CastingManager _castingManager = CastingManager();

  final StreamController<List<CastDevice>> _mergedController =
      StreamController<List<CastDevice>>.broadcast();

  List<CastDevice> _mediaDevices = [];
  List<CastDevice> _mirroringDevices = [];
  StreamSubscription<List<CastDevice>>? _mediaSubscription;
  StreamSubscription<List<CastDevice>>? _mirroringSubscription;

  @override
  Stream<List<CastDevice>> get deviceStream => _mergedController.stream;

  @override
  Future<List<CastDevice>> discoverDevices() async {
    _log.info('Starting device discovery...');

    try {
      await _castingManager.startMediaDiscovery();
    } catch (e) {
      _log.error('Media discovery start failed', e);
    }

    try {
      await _castingManager.startMirroringMonitoring();
    } catch (e) {
      _log.warning('Mirroring monitoring start failed (non-critical): $e');
    }

    _mediaSubscription?.cancel();
    _mirroringSubscription?.cancel();

    _mediaSubscription = _castingManager.discoveredMediaDevices.listen(
      (devices) {
        _mediaDevices = devices;
        _emitMerged();
      },
      onError: (e) {
        _log.error('Media device stream error', e);
      },
    );

    _mirroringSubscription = _castingManager.discoveredMirroringDevices.listen(
      (devices) {
        _mirroringDevices = devices;
        _emitMerged();
      },
      onError: (e) {
        _log.error('Mirroring device stream error', e);
      },
    );

    return [];
  }

  void _emitMerged() {
    final merged = <String, CastDevice>{};

    for (final device in _mediaDevices) {
      merged[device.id] = device;
    }

    for (final device in _mirroringDevices) {
      final existing = merged[device.id];
      if (existing != null) {
        merged[device.id] = existing.copyWith(
          mirroringConnectionState: device.mirroringConnectionState,
          supportsScreenMirroring: device.supportsScreenMirroring,
          name: device.name != 'AirPlay' ? device.name : existing.name,
        );
      } else {
        merged[device.id] = device;
      }
    }

    final result = merged.values.toList();
    _log.debug('Merged device list: ${result.length} device(s)');
    _mergedController.add(result);
  }

  @override
  Future<void> connectToDevice(CastDevice device) async {
    _log.info('Connecting to ${device.name}...');
    await _castingManager.connectMediaDevice(device);
  }

  @override
  Future<void> disconnectDevice(CastDevice device) async {
    _log.info('Disconnecting from ${device.name}...');
    if (device.type == DeviceType.appleAirPlay) {
      await _castingManager.stopAirPlayRouting();
    } else {
      await _castingManager.disconnectMediaDevice();
    }
  }

  void dispose() {
    _mediaSubscription?.cancel();
    _mirroringSubscription?.cancel();
    _mergedController.close();
    _castingManager.stopMediaDiscovery();
    _castingManager.stopMirroringMonitoring();
    _log.info('Disposed');
  }
}
