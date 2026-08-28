import 'dart:async';
import '../models/cast_device.dart';
import 'device_discovery_service.dart';
import '../casting_core/casting_manager.dart';

class RealDeviceDiscoveryService implements DeviceDiscoveryService {
  final CastingManager _castingManager = CastingManager();

  @override
  Stream<List<CastDevice>> get deviceStream => _castingManager.discoveredMediaDevices;

  @override
  Future<List<CastDevice>> discoverDevices() async {
    await _castingManager.startMediaDiscovery();
    return []; // The stream will emit the discovered devices
  }

  @override
  Future<void> connectToDevice(CastDevice device) async {
    await _castingManager.connectMediaDevice(device);
  }

  @override
  Future<void> disconnectDevice(CastDevice device) async {
    await _castingManager.disconnectMediaDevice();
  }

  void dispose() {
    _castingManager.stopMediaDiscovery();
  }
}
