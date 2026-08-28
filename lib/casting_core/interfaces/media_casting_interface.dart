import '../../models/cast_device.dart';
import '../../models/media_item.dart';

abstract class MediaCastingInterface {
  /// Stream of discovered devices that support media casting
  Stream<List<CastDevice>> get discoveredDevices;

  /// Starts discovering devices on the network
  Future<void> startDiscovery();

  /// Stops discovering devices
  Future<void> stopDiscovery();

  /// Connects to a specific device
  Future<void> connect(CastDevice device);

  /// Disconnects from the currently connected device
  Future<void> disconnect();

  /// Loads media onto the connected device
  Future<void> loadMedia(MediaItem media);

  /// Plays the current media
  Future<void> play();

  /// Pauses the current media
  Future<void> pause();

  /// Seeks to a specific position
  Future<void> seek(Duration position);

  /// Sets the volume (0.0 to 1.0)
  Future<void> setVolume(double volume);
}
