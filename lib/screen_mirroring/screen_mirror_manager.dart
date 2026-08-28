import '../models/cast_device.dart';
import '../casting_core/interfaces/screen_mirroring_interface.dart';

class ScreenMirrorManager implements ScreenMirroringInterface {
  @override
  Stream<List<CastDevice>> get discoveredDevices => const Stream.empty();

  @override
  Future<void> startDiscovery() async {
    // TODO: Implement AirPlay/Screen Mirroring discovery
  }

  @override
  Future<void> stopDiscovery() async {
    // TODO: Implement stop discovery
  }

  @override
  Future<void> startMirroring(CastDevice device) async {
    // TODO: Implement start mirroring via MethodChannel
  }

  @override
  Future<void> stopMirroring() async {
    // TODO: Implement stop mirroring via MethodChannel
  }
}
