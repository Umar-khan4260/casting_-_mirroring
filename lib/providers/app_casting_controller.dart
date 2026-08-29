import 'dart:async';
import 'package:flutter/material.dart';
import '../casting_core/casting_manager.dart';
import '../casting_core/interfaces/media_casting_interface.dart';
import '../google_cast/google_cast_manager.dart';
import '../models/cast_device.dart';
import '../models/cast_queue_state.dart';
import '../models/media_player_state.dart';
import '../models/media_item.dart';
import '../utils/cast_logger.dart';

const _log = CastLogger('AppCasting');

class AppCastingController extends ChangeNotifier {
  static final AppCastingController _instance = AppCastingController._();
  factory AppCastingController() => _instance;
  AppCastingController._();

  late final CastingManager _castingManager = CastingManager();

  MediaPlayerState _state = const MediaPlayerState();
  CastQueueState _queueState = const CastQueueState();
  bool _isMirroring = false;
  CastDevice? _mirroringDevice;
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
  bool get isMirroring => _isMirroring;
  CastDevice? get mirroringDevice => _mirroringDevice;

  void _emit() {
    if (_streamController.isClosed) return;
    _streamController.add(_state);
    notifyListeners();
  }

  void _emitQueue() {
    if (_queueStreamController.isClosed) return;
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
          _log.warning('Receiver disconnected');
          _connectedDevice = null;
          _state = _state.copyWith(
            connectedDevice: null,
            status: PlayerStatus.idle,
            isPlaying: false,
            errorMessage: 'Receiver became unavailable.',
          );
          _queueState = const CastQueueState();
          _emit();
          _emitQueue();
        }
      },
      onError: (e) {
        _log.error('Device stream error', e);
      },
    );

    _mediaStatusSubscription = _castingManager.mediaStatusStream.listen(
      _onMediaStatusUpdate,
      onError: (e) {
        _log.error('Media status stream error', e);
      },
    );

    _playerPositionSubscription = _castingManager.playerPositionStream.listen(
      (position) {
        _state = _state.copyWith(position: position);
        _emit();
      },
      onError: (e) {
        _log.error('Player position stream error', e);
      },
    );

    _queueSubscription = _castingManager.queueStream.listen(
      _onQueueUpdate,
      onError: (e) {
        _log.error('Queue stream error', e);
      },
    );

    _log.info('Initialized');
  }

  void _onMediaStatusUpdate(CastMediaStatus status) {
    PlayerStatus newStatus;
    if (status.isError) {
      newStatus = PlayerStatus.error;
      _log.warning('Media error reported by receiver');
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
      errorMessage: newStatus == PlayerStatus.error
          ? (_state.errorMessage ?? 'Playback error on receiver.')
          : null,
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
    if (!_state.isConnected && _connectedDevice == null) {
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Not connected to a device. Please connect first.',
      );
      _emit();
      return;
    }

    _state = _state.copyWith(
      status: PlayerStatus.loading,
      media: media,
      position: Duration.zero,
      duration: media.duration,
      errorMessage: null,
    );
    _emit();

    try {
      await _castingManager.loadMedia(media);
    } on CastMediaException catch (e) {
      _log.error('loadAndCast media error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.message,
      );
      _emit();
    } on CastConnectionException catch (e) {
      _log.error('loadAndCast connection error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.message,
      );
      _emit();
    } catch (e) {
      _log.error('loadAndCast unexpected error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Failed to load media. Please try again.',
      );
      _emit();
    }
  }

  Future<void> castQueue(List<MediaItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) return;

    if (!_state.isConnected && _connectedDevice == null) {
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Not connected to a device. Please connect first.',
      );
      _emit();
      return;
    }

    final media = items[startIndex.clamp(0, items.length - 1)];
    _state = _state.copyWith(
      status: PlayerStatus.loading,
      media: media,
      position: Duration.zero,
      duration: media.duration,
      errorMessage: null,
    );
    _emit();

    try {
      await _castingManager.queueLoad(items, startIndex: startIndex);
    } on CastMediaException catch (e) {
      _log.error('castQueue media error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.message,
      );
      _emit();
    } on CastConnectionException catch (e) {
      _log.error('castQueue connection error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.message,
      );
      _emit();
    } catch (e) {
      _log.error('castQueue unexpected error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Failed to load queue. Please try again.',
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
      _log.error('addToQueue failed', e);
      _state = _state.copyWith(
        errorMessage: 'Failed to add to queue.',
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
      _log.error('addMultipleToQueue failed', e);
      _state = _state.copyWith(
        errorMessage: 'Failed to add items to queue.',
      );
      _emit();
    }
  }

  Future<void> removeFromQueue(int index) async {
    try {
      await _castingManager.queueRemove([index]);
    } catch (e) {
      _log.error('removeFromQueue failed', e);
      _state = _state.copyWith(
        errorMessage: 'Failed to remove from queue.',
      );
      _emit();
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      await _castingManager.queueReorder(oldIndex, newIndex);
    } catch (e) {
      _log.error('reorderQueue failed', e);
      _state = _state.copyWith(
        errorMessage: 'Failed to reorder queue.',
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
    } catch (e) {
      _log.error('clearQueue failed', e);
    }
  }

  Future<void> jumpToQueueItem(int index) async {
    try {
      await _castingManager.queueJumpTo(index);
    } catch (e) {
      _log.error('jumpToQueueItem failed', e);
      _state = _state.copyWith(
        errorMessage: 'Failed to jump to item.',
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
    } on CastMediaException catch (e) {
      _log.error('playPause media error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.message,
      );
      _emit();
    } on CastConnectionException catch (e) {
      _log.error('playPause connection error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.message,
      );
      _emit();
    } catch (e) {
      _log.error('playPause unexpected error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: 'Playback control failed.',
      );
      _emit();
    }
  }

  Future<void> stopMedia() async {
    if (!_state.hasMedia) return;

    try {
      await _castingManager.stopMedia();
    } catch (e) {
      _log.error('stopMedia failed', e);
    }
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
    } on CastMediaException catch (e) {
      _log.error('seek media error', e);
      _state = _state.copyWith(
        errorMessage: e.message,
      );
      _emit();
    } on CastConnectionException catch (e) {
      _log.error('seek connection error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.message,
      );
      _emit();
    } catch (e) {
      _log.error('seek unexpected error', e);
      _state = _state.copyWith(
        errorMessage: 'Seek failed.',
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
    } on CastMediaException catch (e) {
      _log.error('setVolume media error', e);
      _state = _state.copyWith(
        errorMessage: e.message,
      );
      _emit();
    } on CastConnectionException catch (e) {
      _log.error('setVolume connection error', e);
      _state = _state.copyWith(
        status: PlayerStatus.error,
        errorMessage: e.message,
      );
      _emit();
    } catch (e) {
      _log.error('setVolume unexpected error', e);
      _state = _state.copyWith(
        errorMessage: 'Volume control failed.',
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
    } catch (e) {
      _log.error('disconnect failed', e);
    }
    _state = const MediaPlayerState();
    _queueState = const CastQueueState();
    _connectedDevice = null;
    _emit();
    _emitQueue();
    _log.info('Disconnected');
  }

  Future<void> startScreenMirroring(CastDevice device) async {
    try {
      await _castingManager.routeMediaToAirPlay(device);
      _isMirroring = true;
      _mirroringDevice = device;
      _log.info('Screen mirroring started to ${device.name}');
      notifyListeners();
    } catch (e) {
      _log.error('startScreenMirroring failed', e);
      _isMirroring = false;
      _mirroringDevice = null;
      _state = _state.copyWith(
        errorMessage: 'Screen mirroring is not available. '
            'Use Control Center to mirror your screen.',
      );
      _emit();
      notifyListeners();
    }
  }

  Future<void> stopScreenMirroring() async {
    try {
      await _castingManager.stopAirPlayRouting();
    } catch (e) {
      _log.error('stopScreenMirroring failed', e);
    }
    _isMirroring = false;
    _mirroringDevice = null;
    _log.info('Screen mirroring stopped');
    notifyListeners();
  }

  void clearError() {
    if (_state.errorMessage != null) {
      _state = _state.copyWith(errorMessage: null);
      _emit();
    }
  }

  @override
  void dispose() {
    _mediaStatusSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _devicesSubscription?.cancel();
    _queueSubscription?.cancel();
    _streamController.close();
    _queueStreamController.close();
    _log.info('Disposed');
    super.dispose();
  }
}
