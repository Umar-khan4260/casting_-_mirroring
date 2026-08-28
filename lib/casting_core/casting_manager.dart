import '../models/cast_device.dart';
import '../models/media_item.dart';
import 'interfaces/media_casting_interface.dart';
import 'interfaces/screen_mirroring_interface.dart';
import '../google_cast/google_cast_manager.dart';
import '../screen_mirroring/screen_mirror_manager.dart';

class CastingManager {
  final MediaCastingInterface _mediaCasting = GoogleCastManager();
  final ScreenMirroringInterface _screenMirroring = ScreenMirrorManager();

  // Expose streams for UI
  Stream<List<CastDevice>> get discoveredMediaDevices =>
      _mediaCasting.discoveredDevices;
  Stream<List<CastDevice>> get discoveredMirroringDevices =>
      _screenMirroring.discoveredDevices;

  // Media Casting Methods
  Future<void> startMediaDiscovery() => _mediaCasting.startDiscovery();
  Future<void> stopMediaDiscovery() => _mediaCasting.stopDiscovery();
  Future<void> connectMediaDevice(CastDevice device) =>
      _mediaCasting.connect(device);
  Future<void> disconnectMediaDevice() => _mediaCasting.disconnect();
  Future<void> loadMedia(MediaItem media) => _mediaCasting.loadMedia(media);
  Future<void> playMedia() => _mediaCasting.play();
  Future<void> pauseMedia() => _mediaCasting.pause();
  Future<void> seekMedia(Duration position) => _mediaCasting.seek(position);
  Future<void> setMediaVolume(double volume) => _mediaCasting.setVolume(volume);

  // Screen Mirroring Methods
  Future<void> startMirroringDiscovery() => _screenMirroring.startDiscovery();
  Future<void> stopMirroringDiscovery() => _screenMirroring.stopDiscovery();
  Future<void> startScreenMirroring(CastDevice device) =>
      _screenMirroring.startMirroring(device);
  Future<void> stopScreenMirroring() => _screenMirroring.stopMirroring();
}
