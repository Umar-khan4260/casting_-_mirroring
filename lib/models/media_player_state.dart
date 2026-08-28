import 'media_item.dart';
import 'cast_device.dart';

enum PlayerStatus { idle, loading, casting, paused, error }

class MediaPlayerState {
  final PlayerStatus status;
  final MediaItem? media;
  final CastDevice? connectedDevice;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final double volume;
  final bool isMuted;
  final bool isVolumeSupported;
  final String? errorMessage;
  final List<MediaItem> queue;
  final int currentQueueIndex;

  const MediaPlayerState({
    this.status = PlayerStatus.idle,
    this.media,
    this.connectedDevice,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
    this.volume = 0.8,
    this.isMuted = false,
    this.isVolumeSupported = true,
    this.errorMessage,
    this.queue = const [],
    this.currentQueueIndex = 0,
  });

  MediaPlayerState copyWith({
    PlayerStatus? status,
    MediaItem? media,
    CastDevice? connectedDevice,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    double? volume,
    bool? isMuted,
    bool? isVolumeSupported,
    String? errorMessage,
    List<MediaItem>? queue,
    int? currentQueueIndex,
  }) {
    return MediaPlayerState(
      status: status ?? this.status,
      media: media ?? this.media,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isVolumeSupported: isVolumeSupported ?? this.isVolumeSupported,
      errorMessage: errorMessage,
      queue: queue ?? this.queue,
      currentQueueIndex: currentQueueIndex ?? this.currentQueueIndex,
    );
  }

  bool get hasMedia => media != null;
  bool get isConnected => connectedDevice?.isConnected ?? false;
  bool get hasQueue => queue.length > 1;

  String get formattedPosition {
    final totalSeconds = position.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDuration {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (duration.inSeconds == 0) return 0;
    return (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0);
  }
}
