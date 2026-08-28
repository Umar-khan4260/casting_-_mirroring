import 'dart:async';
import 'package:flutter/material.dart';
import '../models/media_player_state.dart';
import '../models/media_item.dart';

class AppCastingController extends ChangeNotifier {
  static final AppCastingController _instance = AppCastingController._();
  factory AppCastingController() => _instance;
  AppCastingController._();

  MediaPlayerState _state = const MediaPlayerState();
  final StreamController<MediaPlayerState> _streamController =
      StreamController<MediaPlayerState>.broadcast();

  Timer? _positionTimer;

  MediaPlayerState get state => _state;
  Stream<MediaPlayerState> get stream => _streamController.stream;
  bool get isCasting =>
      _state.status == PlayerStatus.casting ||
      _state.status == PlayerStatus.paused ||
      _state.status == PlayerStatus.loading;

  void _emit() {
    _streamController.add(_state);
    notifyListeners();
  }

  void loadAndCast(MediaItem media) {
    _positionTimer?.cancel();

    _state = _state.copyWith(status: PlayerStatus.loading, media: media);
    _emit();

    Future.delayed(const Duration(milliseconds: 1500), () {
      _state = _state.copyWith(status: PlayerStatus.casting, isPlaying: true);
      _emit();
      _startPositionTimer();
    });
  }

  void _startPositionTimer() {
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_state.isPlaying) return;
      final newPos = _state.position + const Duration(seconds: 1);
      if (newPos >= _state.duration) {
        _state = _state.copyWith(position: _state.duration, isPlaying: false);
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
    final playing = !_state.isPlaying;
    _state = _state.copyWith(
      isPlaying: playing,
      status: playing ? PlayerStatus.casting : PlayerStatus.paused,
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

  @override
  void dispose() {
    _positionTimer?.cancel();
    _streamController.close();
    super.dispose();
  }
}
