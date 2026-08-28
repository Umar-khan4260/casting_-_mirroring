import '../models/cast_device.dart';
import '../models/media_item.dart';
import '../casting_core/interfaces/media_casting_interface.dart';

class GoogleCastManager implements MediaCastingInterface {
  @override
  Stream<List<CastDevice>> get discoveredDevices => const Stream.empty();

  @override
  Future<void> startDiscovery() async {
    // TODO: Implement Google Cast discovery
  }

  @override
  Future<void> stopDiscovery() async {
    // TODO: Implement stop discovery
  }

  @override
  Future<void> connect(CastDevice device) async {
    // TODO: Implement Google Cast connect
  }

  @override
  Future<void> disconnect() async {
    // TODO: Implement Google Cast disconnect
  }

  @override
  Future<void> loadMedia(MediaItem media) async {
    // TODO: Implement load media
  }

  @override
  Future<void> play() async {
    // TODO: Implement play
  }

  @override
  Future<void> pause() async {
    // TODO: Implement pause
  }

  @override
  Future<void> seek(Duration position) async {
    // TODO: Implement seek
  }

  @override
  Future<void> setVolume(double volume) async {
    // TODO: Implement set volume
  }
}
