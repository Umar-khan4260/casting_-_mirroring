import 'dart:async';
import '../models/cast_device.dart';
import 'device_discovery_service.dart';
import '../casting_core/casting_manager.dart';

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
    await _castingManager.startMediaDiscovery();
    await _castingManager.startMirroringMonitoring();

    _mediaSubscription?.cancel();
    _mirroringSubscription?.cancel();

    _mediaSubscription = _castingManager.discoveredMediaDevices.listen(
      (devices) {
        _mediaDevices = devices;
        _emitMerged();
      },
    );

    _mirroringSubscription = _castingManager.discoveredMirroringDevices.listen(
      (devices) {
        _mirroringDevices = devices;
        _emitMerged();
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

    _mergedController.add(merged.values.toList());
  }

  @override
  Future<void> connectToDevice(CastDevice device) async {
    await _castingManager.connectMediaDevice(device);
  }

  @override
  Future<void> disconnectDevice(CastDevice device) async {
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
  }
}
