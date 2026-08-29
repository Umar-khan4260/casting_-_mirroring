import '../../models/cast_device.dart';
import '../../models/cast_queue_state.dart';
import '../../models/media_item.dart';

/// Represents the real-time media playback status from the Cast receiver.
class CastMediaStatus {
  final bool isPlaying;
  final bool isPaused;
  final bool isBuffering;
  final bool isIdle;
  final bool isError;
  final Duration position;
  final Duration duration;
  final double volume;
  final bool isMuted;
  final String? contentId;

  const CastMediaStatus({
    this.isPlaying = false,
    this.isPaused = false,
    this.isBuffering = false,
    this.isIdle = true,
    this.isError = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 0.8,
    this.isMuted = false,
    this.contentId,
  });

  CastMediaStatus copyWith({
    bool? isPlaying,
    bool? isPaused,
    bool? isBuffering,
    bool? isIdle,
    bool? isError,
    Duration? position,
    Duration? duration,
    double? volume,
    bool? isMuted,
    String? contentId,
  }) {
    return CastMediaStatus(
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      isBuffering: isBuffering ?? this.isBuffering,
      isIdle: isIdle ?? this.isIdle,
      isError: isError ?? this.isError,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      contentId: contentId ?? this.contentId,
    );
  }
}

abstract class MediaCastingInterface {
  /// Stream of discovered devices that support media casting
  Stream<List<CastDevice>> get discoveredDevices;

  /// Stream of real-time media playback status from the Cast receiver.
  Stream<CastMediaStatus> get mediaStatusStream;

  /// Stream of player position updates.
  Stream<Duration> get playerPositionStream;

  /// Stream of queue item changes from the Cast receiver.
  Stream<CastQueueState> get queueStream;

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

  /// Stops the current media
  Future<void> stop();

  /// Seeks to a specific position
  Future<void> seek(Duration position);

  /// Sets the volume (0.0 to 1.0)
  Future<void> setVolume(double volume);

  /// Loads a queue of media items onto the connected device.
  /// Replaces the current queue entirely.
  Future<void> queueLoad(List<MediaItem> items, {int startIndex});

  /// Inserts media items into the queue after the currently playing item.
  Future<void> queueInsert(List<MediaItem> items);

  /// Inserts a media item and immediately jumps to play it.
  Future<void> queueInsertAndPlay(MediaItem item);

  /// Removes items from the queue by their index positions.
  Future<void> queueRemove(List<int> indices);

  /// Reorders items in the queue.
  Future<void> queueReorder(int oldIndex, int newIndex);

  /// Clears the entire queue.
  Future<void> queueClear();

  /// Jumps to play a specific item in the queue by index.
  Future<void> queueJumpTo(int index);

  /// Plays the next item in the queue.
  Future<void> queueNext();

  /// Plays the previous item in the queue.
  Future<void> queuePrevious();
}
