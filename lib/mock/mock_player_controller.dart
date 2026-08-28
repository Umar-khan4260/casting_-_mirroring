import 'dart:async';
import '../models/media_player_state.dart';
import '../models/media_item.dart';
import '../models/cast_device.dart';
import '../mock/mock_media_data.dart';

class MockMediaPlayerController {
  MediaPlayerState _state = const MediaPlayerState();
  final StreamController<MediaPlayerState> _controller =
      StreamController<MediaPlayerState>.broadcast();

  Stream<MediaPlayerState> get stream => _controller.stream;
  MediaPlayerState get state => _state;

  Timer? _positionTimer;

  void _emit() {
    _controller.add(_state);
  }

  void loadAndCast(MediaItem media) {
    _positionTimer?.cancel();

    _state = _state.copyWith(
      status: PlayerStatus.loading,
      media: media,
      position: Duration.zero,
      duration: media.duration,
      isPlaying: false,
      connectedDevice: const CastDevice(
        id: '1',
        name: 'Living Room TV',
        type: 'tv',
        connectionState: DeviceConnectionState.connected,
        mediaCasting: true,
        screenMirroring: true,
      ),
      queue: MockMediaData.allMedia
          .where((m) => m.type == media.type)
          .toList(),
      currentQueueIndex: 0,
    );
    _emit();

    Future.delayed(const Duration(milliseconds: 1500), () {
      _state = _state.copyWith(
        status: PlayerStatus.casting,
        isPlaying: true,
      );
      _emit();
      _startPositionTimer();
    });
  }

  void _startPositionTimer() {
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_state.isPlaying) return;
      final newPos = _state.position + const Duration(seconds: 1);
      if (newPos >= _state.duration) {
        _state = _state.copyWith(
          position: _state.duration,
          isPlaying: false,
        );
        _positionTimer?.cancel();
      } else {
        _state = _state.copyWith(position: newPos);
      }
      _emit();
    });
  }

  void playPause() {
    if (_state.status != PlayerStatus.casting &&
        _state.status != PlayerStatus.paused) {
      return;
    }
    final isPlaying = !_state.isPlaying;
    _state = _state.copyWith(
      isPlaying: isPlaying,
      status: isPlaying ? PlayerStatus.casting : PlayerStatus.paused,
    );
    _emit();
  }

  void seek(Duration position) {
    _state = _state.copyWith(position: position);
    _emit();
  }

  void seekToFraction(double fraction) {
    final targetSeconds = (fraction * _state.duration.inSeconds).round();
    seek(Duration(seconds: targetSeconds));
  }

  void setVolume(double volume) {
    _state = _state.copyWith(volume: volume.clamp(0.0, 1.0), isMuted: false);
    _emit();
  }

  void toggleMute() {
    _state = _state.copyWith(isMuted: !_state.isMuted);
    _emit();
  }

  void skipNext() {
    if (!_state.hasQueue) return;
    final nextIndex = _state.currentQueueIndex + 1;
    if (nextIndex >= _state.queue.length) return;
    loadAndCast(_state.queue[nextIndex]);
  }

  void skipPrevious() {
    if (!_state.hasQueue) return;
    final prevIndex = _state.currentQueueIndex - 1;
    if (prevIndex < 0) return;
    loadAndCast(_state.queue[prevIndex]);
  }

  void disconnect() {
    _positionTimer?.cancel();
    _state = const MediaPlayerState();
    _emit();
  }

  void dispose() {
    _positionTimer?.cancel();
    _controller.close();
  }
}
