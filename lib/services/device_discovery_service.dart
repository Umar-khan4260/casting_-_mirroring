import '../models/cast_device.dart';

abstract class DeviceDiscoveryService {
  Future<List<CastDevice>> discoverDevices();
  Future<void> connectToDevice(CastDevice device);
  Future<void> disconnectDevice(CastDevice device);
  Stream<List<CastDevice>> get deviceStream;
}
