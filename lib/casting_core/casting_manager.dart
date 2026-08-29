import '../models/cast_device.dart';
import '../models/cast_queue_state.dart';
import '../models/media_item.dart';
import 'interfaces/media_casting_interface.dart';
import 'interfaces/screen_mirroring_interface.dart';
import '../google_cast/google_cast_manager.dart';
import '../screen_mirroring/screen_mirror_manager.dart';

class CastingManager {
  final MediaCastingInterface _mediaCasting = GoogleCastManager();
  final ScreenMirroringInterface _screenMirroring = ScreenMirrorManager();

  Stream<List<CastDevice>> get discoveredMediaDevices =>
      _mediaCasting.discoveredDevices;
  Stream<List<CastDevice>> get discoveredMirroringDevices =>
      _screenMirroring.discoveredDevices;
  Stream<CastMediaStatus> get mediaStatusStream =>
      _mediaCasting.mediaStatusStream;
  Stream<Duration> get playerPositionStream =>
      _mediaCasting.playerPositionStream;
  Stream<CastQueueState> get queueStream => _mediaCasting.queueStream;

  Future<void> startMediaDiscovery() => _mediaCasting.startDiscovery();
  Future<void> stopMediaDiscovery() => _mediaCasting.stopDiscovery();
  Future<void> connectMediaDevice(CastDevice device) =>
      _mediaCasting.connect(device);
  Future<void> disconnectMediaDevice() => _mediaCasting.disconnect();
  Future<void> loadMedia(MediaItem media) => _mediaCasting.loadMedia(media);
  Future<void> playMedia() => _mediaCasting.play();
  Future<void> pauseMedia() => _mediaCasting.pause();
  Future<void> stopMedia() => _mediaCasting.stop();
  Future<void> seekMedia(Duration position) => _mediaCasting.seek(position);
  Future<void> setMediaVolume(double volume) => _mediaCasting.setVolume(volume);

  Future<void> queueLoad(List<MediaItem> items, {int startIndex = 0}) =>
      _mediaCasting.queueLoad(items, startIndex: startIndex);
  Future<void> queueInsert(List<MediaItem> items) =>
      _mediaCasting.queueInsert(items);
  Future<void> queueInsertAndPlay(MediaItem item) =>
      _mediaCasting.queueInsertAndPlay(item);
  Future<void> queueRemove(List<int> indices) =>
      _mediaCasting.queueRemove(indices);
  Future<void> queueReorder(int oldIndex, int newIndex) =>
      _mediaCasting.queueReorder(oldIndex, newIndex);
  Future<void> queueClear() => _mediaCasting.queueClear();
  Future<void> queueJumpTo(int index) => _mediaCasting.queueJumpTo(index);
  Future<void> queueNext() => _mediaCasting.queueNext();
  Future<void> queuePrevious() => _mediaCasting.queuePrevious();

  Future<void> startMirroringDiscovery() => _screenMirroring.startDiscovery();
  Future<void> stopMirroringDiscovery() => _screenMirroring.stopDiscovery();
  Future<void> startScreenMirroring(CastDevice device) =>
      _screenMirroring.startMirroring(device);
  Future<void> stopScreenMirroring() => _screenMirroring.stopMirroring();
}
