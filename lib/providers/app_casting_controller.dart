import 'dart:async';
import 'package:flutter/material.dart';
import '../casting_core/casting_manager.dart';
import '../casting_core/interfaces/media_casting_interface.dart';
import '../google_cast/google_cast_manager.dart';
import '../models/cast_device.dart';
import '../models/cast_queue_state.dart';
import '../models/media_player_state.dart';
import '../models/media_item.dart';

class AppCastingController extends ChangeNotifier {
  static final AppCastingController _instance = AppCastingController._();
  factory AppCastingController() => _instance;
  AppCastingController._();

  late final CastingManager _castingManager = CastingManager();

  MediaPlayerState _state = const MediaPlayerState();
  CastQueueState _queueState = const CastQueueState();
  final StreamController<MediaPlayerState> _streamController =
      StreamController<MediaPlayerState>.broadcast();
  final StreamController<CastQueueState> _queueStreamController =
      StreamController<CastQueueState>.broadcast();

  StreamSubscription? _mediaStatusSubscription;
  StreamSubscription? _playerPositionSubscription;
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _queueSubscription;
  CastDevice? _connectedDevice;

  MediaPlayerState get state => _state;
  CastQueueState get queueState => _queueState;
  Stream<MediaPlayerState> get stream => _streamController.stream;
  Stream<CastQueueState> get queueStream => _queueStreamController.stream;
  CastingManager get castingManager => _castingManager;
  bool get isCasting =>
      _state.status == PlayerStatus.casting ||
      _state.status == PlayerStatus.paused ||
      _state.status == PlayerStatus.loading;

  void _emit() {
    _streamController.add(_state);
    notifyListeners();
  }

  void _emitQueue() {
    _queueStreamController.add(_queueState);
    notifyListeners();
  }

  void initialize() {
    GoogleCastManager().initialize();

    _devicesSubscription = _castingManager.discoveredMediaDevices.listen(
      (devices) {
        final connected = devices.where(
          (d) => d.connectionState == DeviceConnectionState.connected,
        );
        if (connected.isNotEmpty) {
          _connectedDevice = connected.first;
          _state = _state.copyWith(connectedDevice: _connectedDevice);
          _emit();
        } else if (_connectedDevice != null) {
          _connectedDevice = null;
          _state = _state.copyWith(
            connectedDevice: null,
            status: PlayerStatus.idle,
            isPlaying: false,
          );
          _queueState = const CastQueueState();
          _emit();
          _emitQueue();
        }
      },
    );

    _mediaStatusSubscription = _castingManager.mediaStatusStream.listen(
      _onMediaStatusUpdate,
    );

    _playerPositionSubscription = _castingManager.playerPositionStream.listen(
      (position) {
        _state = _state.copyWith(position: position);
        _emit();
      },
    );

    _queueSubscription = _castingManager.queueStream.listen(
      _onQueueUpdate,
    );
  }

  void _onMediaStatusUpdate(CastMediaStatus status) {
    PlayerStatus newStatus;
    if (status.isError) {
      newStatus = PlayerStatus.error;
    } else if (status.isPlaying) {
      newStatus = PlayerStatus.casting;
    } else if (status.isPaused) {
      newStatus = PlayerStatus.paused;
    } else if (status.isBuffering) {
      newStatus = PlayerStatus.loading;
    } else if (status.isIdle && _state.hasMedia) {
      newStatus = PlayerStatus.idle;
    } else {
      newStatus = _state.hasMedia ? PlayerStatus.casting : PlayerStatus.idle;
    }

    _state = _state.copyWith(
      status: newStatus,
      isPlaying: status.isPlaying,
      position: status.position,
      duration: status.duration,
      volume: status.volume,
      isMuted: status.isMuted,
    );
    _emit();
  }

  void _onQueueUpdate(CastQueueState queueState) {
    _queueState = queueState;

    if (queueState.currentMedia != null &&
        queueState.currentMedia!.id != _state.media?.id) {
      _state = _state.copyWith(
        media: queueState.currentMedia,
        position: Duration.zero,
        duration: queueState.currentMedia!.duration,
      );
    }

    _state = _state.copyWith(
      queue: queueState.items.map((i) => i.media).toList(),
      currentQueueIndex: queueState.currentIndex,
    );
    _emit();
    _emitQueue();
  }

  Future<void> loadAndCast(MediaItem media) async {
    _state = _state.copyWith(
      status: PlayerStatus.loading,
      media: media,
      position: Duration.zero,
      duration: media.duration,
    );
    _emit();

    try {
      await _castingManager.loadMedia(media);
    } catch (e) {
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Failed to load media: $e',
      );
      _emit();
    }
  }

  Future<void> castQueue(List<MediaItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;

    final media = items[startIndex.clamp(0, items.length - 1)];
    _state = _state.copyWith(
      status: PlayerStatus.loading,
      media: media,
      position: Duration.zero,
      duration: media.duration,
    );
    _emit();

    try {
      await _castingManager.queueLoad(items, startIndex: startIndex);
    } catch (e) {
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Failed to load queue: $e',
      );
      _emit();
    }
  }

  Future<void> addToQueue(MediaItem media) async {
    if (!isCasting && _queueState.isEmpty) {
      await loadAndCast(media);
      return;
    }

    try {
      await _castingManager.queueInsert([media]);
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to add to queue: $e',
      );
      _emit();
    }
  }

  Future<void> addMultipleToQueue(List<MediaItem> items) async {
    if (items.isEmpty) return;

    if (!isCasting && _queueState.isEmpty) {
      await castQueue(items);
      return;
    }

    try {
      await _castingManager.queueInsert(items);
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to add items to queue: $e',
      );
      _emit();
    }
  }

  Future<void> removeFromQueue(int index) async {
    try {
      await _castingManager.queueRemove([index]);
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to remove from queue: $e',
      );
      _emit();
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      await _castingManager.queueReorder(oldIndex, newIndex);
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to reorder queue: $e',
      );
      _emit();
    }
  }

  Future<void> clearQueue() async {
    try {
      await _castingManager.queueClear();
      _queueState = const CastQueueState();
      _state = _state.copyWith(queue: [], currentQueueIndex: 0);
      _emit();
      _emitQueue();
    } catch (_) {}
  }

  Future<void> jumpToQueueItem(int index) async {
    try {
      await _castingManager.queueJumpTo(index);
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to jump to item: $e',
      );
      _emit();
    }
  }

  Future<void> playPause() async {
    if (_state.status != PlayerStatus.casting &&
        _state.status != PlayerStatus.paused) {
      return;
    }

    try {
      if (_state.isPlaying) {
        await _castingManager.pauseMedia();
      } else {
        await _castingManager.playMedia();
      }
    } catch (e) {
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Playback control failed: $e',
      );
      _emit();
    }
  }

  Future<void> stopMedia() async {
    if (!_state.hasMedia) return;

    try {
      await _castingManager.stopMedia();
    } catch (_) {}
    _state = _state.copyWith(
      status: PlayerStatus.idle,
      isPlaying: false,
      position: Duration.zero,
    );
    _emit();
  }

  Future<void> seek(Duration position) async {
    try {
      await _castingManager.seekMedia(position);
      _state = _state.copyWith(position: position);
      _emit();
    } catch (e) {
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Seek failed: $e',
      );
      _emit();
    }
  }

  void seekToFraction(double fraction) {
    final targetSeconds = (fraction * _state.duration.inSeconds).round();
    seek(Duration(seconds: targetSeconds));
  }

  Future<void> setVolume(double volume) async {
    try {
      await _castingManager.setMediaVolume(volume);
      _state = _state.copyWith(volume: volume.clamp(0.0, 1.0), isMuted: false);
      _emit();
    } catch (e) {
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Volume control failed: $e',
      );
      _emit();
    }
  }

  void toggleMute() {
    final newMuted = !_state.isMuted;
    if (newMuted) {
      _castingManager.setMediaVolume(0.0);
    } else {
      _castingManager.setMediaVolume(_state.volume);
    }
    _state = _state.copyWith(isMuted: newMuted);
    _emit();
  }

  void skipNext() {
    if (_queueState.hasNextItem) {
      jumpToQueueItem(_queueState.currentIndex + 1);
    } else if (_state.hasQueue) {
      final nextIndex = _state.currentQueueIndex + 1;
      if (nextIndex < _state.queue.length) {
        loadAndCast(_state.queue[nextIndex]);
      }
    }
  }

  void skipPrevious() {
    if (_queueState.hasPreviousItem) {
      jumpToQueueItem(_queueState.currentIndex - 1);
    } else if (_state.hasQueue) {
      final prevIndex = _state.currentQueueIndex - 1;
      if (prevIndex >= 0) {
        loadAndCast(_state.queue[prevIndex]);
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await _castingManager.disconnectMediaDevice();
    } catch (_) {}
    _state = const MediaPlayerState();
    _queueState = const CastQueueState();
    _connectedDevice = null;
    _emit();
    _emitQueue();
  }

  @override
  void dispose() {
    _mediaStatusSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _devicesSubscription?.cancel();
    _queueSubscription?.cancel();
    _streamController.close();
    _queueStreamController.close();
    super.dispose();
  }
}
