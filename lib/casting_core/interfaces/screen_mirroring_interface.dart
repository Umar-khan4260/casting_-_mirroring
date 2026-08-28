import '../../models/cast_device.dart';

abstract class ScreenMirroringInterface {
  /// Stream of discovered devices that support screen mirroring
  Stream<List<CastDevice>> get discoveredDevices;

  /// Starts discovering devices on the network
  Future<void> startDiscovery();

  /// Stops discovering devices
  Future<void> stopDiscovery();

  /// Starts screen mirroring to the specified device
  Future<void> startMirroring(CastDevice device);

  /// Stops the current screen mirroring session
  Future<void> stopMirroring();
}
