import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import '../models/cast_device.dart';
import '../models/cast_queue_state.dart';
import '../models/media_item.dart';
import '../casting_core/interfaces/media_casting_interface.dart';
import '../utils/cast_logger.dart';

const _timeout = Duration(seconds: 15);
const _log = CastLogger('GoogleCast');

class GoogleCastManager implements MediaCastingInterface {
  static final GoogleCastManager _instance = GoogleCastManager._();
  factory GoogleCastManager() => _instance;

  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();

  final StreamController<CastMediaStatus> _mediaStatusController =
      StreamController<CastMediaStatus>.broadcast();

  final StreamController<Duration> _playerPositionController =
      StreamController<Duration>.broadcast();

  final StreamController<CastQueueState> _queueController =
      StreamController<CastQueueState>.broadcast();

  List<CastDevice> _latestDevices = [];
  CastMediaStatus _latestStatus = const CastMediaStatus();
  Duration _lastPosition = Duration.zero;
  CastQueueState _latestQueue = const CastQueueState();
  int _nextItemId = 1;
  StreamSubscription? _mediaStatusSubscription;
  StreamSubscription? _playerPositionSubscription;
  StreamSubscription? _sessionSubscription;
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _queueSubscription;
  bool _initialized = false;

  GoogleCastManager._();

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;

    try {
      _initListeners();
      _log.info('Initialized');
    } catch (e, st) {
      _log.error('Failed to initialize', e, st);
    }
  }

  void _initListeners() {
    try {
      _discoverySubscription =
          GoogleCastDiscoveryManager.instance.devicesStream.listen(
        (devices) {
          _latestDevices = devices
              .map((d) => CastDevice(
                    id: d.deviceID,
                    name: d.friendlyName,
                    type: DeviceType.googleCast,
                    connectionState: _getConnectionState(),
                    supportsMediaCasting: true,
                    supportsScreenMirroring: false,
                  ))
              .toList();
          _devicesController.add(_latestDevices);
          _log.debug('Discovered ${_latestDevices.length} device(s)');
        },
        onError: (e) {
          _log.error('Discovery stream error', e);
        },
      );
    } catch (e) {
      _log.error('Failed to init discovery listener', e);
    }

    try {
      _sessionSubscription =
          GoogleCastSessionManager.instance.currentSessionStream.listen(
        (_) {
          final newState = _getConnectionState();
          final updated = _latestDevices
              .map((device) => device.copyWith(connectionState: newState))
              .toList();
          _latestDevices = updated;
          _devicesController.add(updated);

          if (newState == DeviceConnectionState.disconnected &&
              _latestStatus.isPlaying) {
            _latestStatus = const CastMediaStatus(isError: true);
            _mediaStatusController.add(_latestStatus);
            _log.warning('Receiver disconnected during playback');
          }

          final session =
              GoogleCastSessionManager.instance.currentSession;
          if (session != null) {
            _latestStatus = _latestStatus.copyWith(
              volume: session.currentDeviceVolume,
              isMuted: session.currentDeviceMuted,
            );
            _mediaStatusController.add(_latestStatus);
          }
        },
        onError: (e) {
          _log.error('Session stream error', e);
        },
      );
    } catch (e) {
      _log.error('Failed to init session listener', e);
    }

    try {
      _mediaStatusSubscription =
          GoogleCastRemoteMediaClient.instance.mediaStatusStream.listen(
        (status) {
          if (status == null) {
            _latestStatus = const CastMediaStatus();
            _mediaStatusController.add(_latestStatus);
            return;
          }

          final playerState = status.playerState;
          final mediaInfo = status.mediaInformation;
          final duration = mediaInfo?.duration ?? Duration.zero;
          final contentId = mediaInfo?.contentId;

          final isIdle = playerState == CastMediaPlayerState.idle ||
              playerState == CastMediaPlayerState.unknown;
          final idleReason = status.idleReason;
          final isError = isIdle &&
              idleReason == GoogleCastMediaIdleReason.error;
          final isMediaEnded = isIdle &&
              idleReason == GoogleCastMediaIdleReason.finished;

          if (isError) {
            _log.warning('Receiver reported media error (idleReason: $idleReason)');
          }

          _latestStatus = CastMediaStatus(
            isPlaying: playerState == CastMediaPlayerState.playing,
            isPaused: playerState == CastMediaPlayerState.paused,
            isBuffering: playerState == CastMediaPlayerState.buffering,
            isIdle: isIdle && !isError && !isMediaEnded,
            isError: isError,
            position: _lastPosition,
            duration: duration,
            volume: (status.volume).toDouble().clamp(0.0, 1.0),
            isMuted: status.isMuted,
            contentId: contentId,
          );
          _mediaStatusController.add(_latestStatus);
        },
        onError: (e) {
          _log.error('Media status stream error', e);
        },
      );
    } catch (e) {
      _log.error('Failed to init media status listener', e);
    }

    try {
      _playerPositionSubscription =
          GoogleCastRemoteMediaClient.instance.playerPositionStream.listen(
        (position) {
          _lastPosition = position;
          _playerPositionController.add(position);

          _latestStatus = _latestStatus.copyWith(position: position);
          _mediaStatusController.add(_latestStatus);
        },
        onError: (e) {
          _log.error('Player position stream error', e);
        },
      );
    } catch (e) {
      _log.error('Failed to init player position listener', e);
    }

    try {
      _queueSubscription =
          GoogleCastRemoteMediaClient.instance.queueItemsStream.listen(
        (queueItems) {
          _onQueueItemsUpdated(queueItems);
        },
        onError: (e) {
          _log.error('Queue stream error', e);
        },
      );
    } catch (e) {
      _log.error('Failed to init queue listener', e);
    }
  }

  DeviceConnectionState _getConnectionState() {
    final state = GoogleCastSessionManager.instance.connectionState;
    switch (state) {
      case GoogleCastConnectState.connected:
        return DeviceConnectionState.connected;
      case GoogleCastConnectState.connecting:
        return DeviceConnectionState.connecting;
      case GoogleCastConnectState.disconnecting:
        return DeviceConnectionState.disconnecting;
      case GoogleCastConnectState.disconnected:
        return DeviceConnectionState.disconnected;
    }
  }

  bool get isConnected =>
      _getConnectionState() == DeviceConnectionState.connected;

  String _contentTypeForMediaType(MediaType type) {
    switch (type) {
      case MediaType.video:
        return 'video/mp4';
      case MediaType.music:
        return 'audio/mpeg';
      case MediaType.photo:
        return 'image/jpeg';
    }
  }

  void _validateMediaUrl(MediaItem media) {
    final url = media.mediaUrl ?? media.thumbnailUrl;
    if (url.isEmpty) {
      throw CastMediaException('Media has no URL. Cannot cast.');
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      throw CastMediaException('Invalid media URL: $url');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw CastMediaException(
        'Unsupported URL scheme "${uri.scheme}". Only http/https URLs can be cast.',
      );
    }
  }

  @override
  Stream<List<CastDevice>> get discoveredDevices => _devicesController.stream;

  @override
  Stream<CastMediaStatus> get mediaStatusStream =>
      _mediaStatusController.stream;

  @override
  Stream<Duration> get playerPositionStream =>
      _playerPositionController.stream;

  @override
  Stream<CastQueueState> get queueStream => _queueController.stream;

  @override
  Future<void> startDiscovery() async {
    if (kIsWeb) return;
    try {
      await GoogleCastDiscoveryManager.instance.startDiscovery();
      _log.info('Discovery started');
    } catch (e) {
      _log.error('startDiscovery failed', e);
      throw CastDiscoveryException(
        'Could not start device discovery. '
        'Check that local network access is enabled in Settings.',
      );
    }
  }

  @override
  Future<void> stopDiscovery() async {
    if (kIsWeb) return;
    try {
      await GoogleCastDiscoveryManager.instance.stopDiscovery();
      _log.info('Discovery stopped');
    } catch (e) {
      _log.error('stopDiscovery failed', e);
    }
  }

  @override
  Future<void> connect(CastDevice device) async {
    if (kIsWeb) return;
    _log.info('Connecting to ${device.name} (${device.id})...');
    try {
      final target = GoogleCastDiscoveryManager.instance.devices
          .firstWhere((d) => d.deviceID == device.id);
      await GoogleCastSessionManager.instance
          .startSessionWithDevice(target)
          .timeout(_timeout, onTimeout: () {
        throw CastConnectionException(
          'Connection to ${device.name} timed out. '
          'The device may be unavailable or too far away.',
        );
      });
      _log.info('Connected to ${device.name}');
    } on CastConnectionException {
      rethrow;
    } on StateError {
      throw CastConnectionException(
        'Device "${device.name}" not found on the network. '
        'It may have gone offline.',
      );
    } catch (e) {
      _log.error('connect failed', e);
      throw CastConnectionException(
        'Failed to connect to ${device.name}. '
        'Make sure the device is on and connected to the same network.',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (kIsWeb) return;
    _log.info('Disconnecting...');
    try {
      await GoogleCastSessionManager.instance.endSessionAndStopCasting();
      _log.info('Disconnected');
    } catch (e) {
      _log.error('disconnect failed', e);
      throw CastConnectionException('Failed to disconnect from receiver.');
    }
  }

  @override
  Future<void> loadMedia(MediaItem media) async {
    if (kIsWeb) return;
    _validateMediaUrl(media);

    if (!isConnected) {
      throw CastConnectionException(
        'Not connected to a receiver. Connect to a device first.',
      );
    }

    final url = media.mediaUrl ?? media.thumbnailUrl;
    final contentType = media.mediaUrl != null
        ? media.contentType
        : _contentTypeForMediaType(media.type);

    GoogleCastMediaMetadata? metadata;
    switch (media.type) {
      case MediaType.video:
        metadata = GoogleCastMovieMediaMetadata(
          title: media.title,
          subtitle: media.subtitle,
        );
        break;
      case MediaType.music:
        metadata = GoogleCastMusicMediaMetadata(
          title: media.title,
          artist: media.artist,
          albumName: media.album,
        );
        break;
      case MediaType.photo:
        metadata = GoogleCastPhotoMediaMetadata(
          title: media.title,
        );
        break;
    }

    final mediaInfo = GoogleCastMediaInformationIOS(
      contentId: url,
      streamType: CastMediaStreamType.buffered,
      contentType: contentType,
      metadata: metadata,
      duration: media.duration.inSeconds > 0 ? media.duration : null,
    );

    try {
      await GoogleCastRemoteMediaClient.instance
          .loadMedia(
            mediaInfo,
            autoPlay: true,
          )
          .timeout(_timeout, onTimeout: () {
        throw CastMediaException(
          'Loading media timed out. The receiver may be slow or the URL unreachable.',
        );
      });
      _log.info('Loaded media: ${media.title}');
    } on CastMediaException {
      rethrow;
    } catch (e) {
      _log.error('loadMedia failed', e);
      throw CastMediaException(
        'Failed to load "${media.title}" on the receiver. '
        'The media URL may be unavailable or the format unsupported.',
      );
    }
  }

  @override
  Future<void> play() async {
    if (kIsWeb) return;
    if (!isConnected) {
      throw CastConnectionException('Not connected to a receiver.');
    }
    try {
      await GoogleCastRemoteMediaClient.instance.play();
    } catch (e) {
      _log.error('play failed', e);
      throw CastMediaException('Failed to resume playback.');
    }
  }

  @override
  Future<void> pause() async {
    if (kIsWeb) return;
    if (!isConnected) {
      throw CastConnectionException('Not connected to a receiver.');
    }
    try {
      await GoogleCastRemoteMediaClient.instance.pause();
    } catch (e) {
      _log.error('pause failed', e);
      throw CastMediaException('Failed to pause playback.');
    }
  }

  @override
  Future<void> stop() async {
    if (kIsWeb) return;
    if (!isConnected) return;
    try {
      await GoogleCastRemoteMediaClient.instance.stop();
    } catch (e) {
      _log.error('stop failed', e);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (kIsWeb) return;
    if (!isConnected) {
      throw CastConnectionException('Not connected to a receiver.');
    }
    try {
      await GoogleCastRemoteMediaClient.instance.seek(
        GoogleCastMediaSeekOption(position: position),
      );
    } catch (e) {
      _log.error('seek failed', e);
      throw CastMediaException('Failed to seek.');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    if (kIsWeb) return;
    if (!isConnected) {
      throw CastConnectionException('Not connected to a receiver.');
    }
    try {
      GoogleCastSessionManager.instance
          .setDeviceVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      _log.error('setVolume failed', e);
      throw CastMediaException('Failed to set volume.');
    }
  }

  GoogleCastMediaInformationIOS _buildMediaInfo(MediaItem media) {
    final url = media.mediaUrl ?? media.thumbnailUrl;
    final contentType = media.mediaUrl != null
        ? media.contentType
        : _contentTypeForMediaType(media.type);

    GoogleCastMediaMetadata? metadata;
    switch (media.type) {
      case MediaType.video:
        metadata = GoogleCastMovieMediaMetadata(
          title: media.title,
          subtitle: media.subtitle,
        );
        break;
      case MediaType.music:
        metadata = GoogleCastMusicMediaMetadata(
          title: media.title,
          artist: media.artist,
          albumName: media.album,
        );
        break;
      case MediaType.photo:
        metadata = GoogleCastPhotoMediaMetadata(
          title: media.title,
        );
        break;
    }

    return GoogleCastMediaInformationIOS(
      contentId: url,
      streamType: CastMediaStreamType.buffered,
      contentType: contentType,
      metadata: metadata,
      duration: media.duration.inSeconds > 0 ? media.duration : null,
    );
  }

  void _onQueueItemsUpdated(List<dynamic> rawItems) {
    final status = GoogleCastRemoteMediaClient.instance.mediaStatus;
    final currentItemId = status?.currentItemId;

    final castItems = <CastQueueItem>[];
    for (int i = 0; i < rawItems.length; i++) {
      final raw = rawItems[i];
      final itemId = raw.itemId ?? _nextItemId++;
      final mediaInfo = raw.mediaInformation;
      if (mediaInfo == null) continue;

      final metadata = mediaInfo.metadata;
      String title = '';
      String subtitle = '';
      String? artist;
      String? album;
      if (metadata is GoogleCastMovieMediaMetadata) {
        title = metadata.title ?? '';
        subtitle = metadata.subtitle ?? '';
      } else if (metadata is GoogleCastMusicMediaMetadata) {
        title = metadata.title ?? '';
        artist = metadata.artist;
        album = metadata.albumName;
      } else if (metadata is GoogleCastPhotoMediaMetadata) {
        title = metadata.title ?? '';
      }

      final duration = mediaInfo.duration ?? Duration.zero;
      final mediaUrl = mediaInfo.contentId ?? '';
      final contentType = mediaInfo.contentType ?? 'video/mp4';

      MediaType type = MediaType.video;
      if (contentType.startsWith('audio/')) {
        type = MediaType.music;
      } else if (contentType.startsWith('image/')) {
        type = MediaType.photo;
      }

      final mediaItem = MediaItem(
        id: 'cast_$itemId',
        title: title,
        subtitle: subtitle,
        thumbnailUrl: mediaUrl,
        mediaUrl: mediaUrl,
        contentType: contentType,
        duration: duration,
        type: type,
        dateAdded: DateTime.now(),
        artist: artist,
        album: album,
      );

      castItems.add(CastQueueItem(
        media: mediaItem,
        castItemId: itemId,
        isCurrentlyPlaying: itemId == currentItemId,
      ));
    }

    int newIndex = 0;
    if (currentItemId != null) {
      for (int i = 0; i < castItems.length; i++) {
        if (castItems[i].castItemId == currentItemId) {
          newIndex = i;
          break;
        }
      }
    }

    _latestQueue = _latestQueue.copyWith(
      items: castItems,
      currentIndex: newIndex,
    );
    _queueController.add(_latestQueue);
  }

  GoogleCastQueueItem _mediaToQueueItem(MediaItem media) {
    final mediaInfo = _buildMediaInfo(media);
    final itemId = _nextItemId++;
    return GoogleCastQueueItem(
      mediaInformation: mediaInfo,
      autoPlay: true,
      itemId: itemId,
    );
  }

  @override
  Future<void> queueLoad(List<MediaItem> items, {int startIndex = 0}) async {
    if (kIsWeb || items.isEmpty) return;
    if (!isConnected) {
      throw CastConnectionException('Not connected to a receiver.');
    }
    try {
      _nextItemId = 1;
      final queueItems = items.map(_mediaToQueueItem).toList();
      final options = GoogleCastQueueLoadOptions(
        startIndex: startIndex.clamp(0, items.length - 1),
        repeatMode: GoogleCastMediaRepeatMode.off,
      );
      await GoogleCastRemoteMediaClient.instance.queueLoadItems(
        queueItems,
        options: options,
      );
    } catch (e) {
      _log.error('queueLoad failed', e);
      throw CastMediaException('Failed to load queue on receiver.');
    }
  }

  @override
  Future<void> queueInsert(List<MediaItem> items) async {
    if (kIsWeb || items.isEmpty) return;
    if (!isConnected) {
      throw CastConnectionException('Not connected to a receiver.');
    }
    try {
      final queueItems = items.map(_mediaToQueueItem).toList();
      await GoogleCastRemoteMediaClient.instance.queueInsertItems(queueItems);
    } catch (e) {
      _log.error('queueInsert failed', e);
      throw CastMediaException('Failed to add items to queue.');
    }
  }

  @override
  Future<void> queueInsertAndPlay(MediaItem item) async {
    if (kIsWeb) return;
    if (!isConnected) {
      throw CastConnectionException('Not connected to a receiver.');
    }
    try {
      final queueItem = _mediaToQueueItem(item);
      final status = GoogleCastRemoteMediaClient.instance.mediaStatus;
      final currentItemId = status?.currentItemId;
      if (currentItemId != null) {
        await GoogleCastRemoteMediaClient.instance.queueInsertItemAndPlay(
          queueItem,
          beforeItemWithId: currentItemId,
        );
      } else {
        await GoogleCastRemoteMediaClient.instance.queueInsertItems([queueItem]);
      }
    } catch (e) {
      _log.error('queueInsertAndPlay failed', e);
      throw CastMediaException('Failed to insert and play item.');
    }
  }

  @override
  Future<void> queueRemove(List<int> indices) async {
    if (kIsWeb || indices.isEmpty) return;
    if (!isConnected) return;
    try {
      final currentItems = _latestQueue.items;
      final idsToRemove = <int>[];
      for (final index in indices) {
        if (index >= 0 && index < currentItems.length) {
          idsToRemove.add(currentItems[index].castItemId);
        }
      }
      if (idsToRemove.isNotEmpty) {
        await GoogleCastRemoteMediaClient.instance
            .queueRemoveItemsWithIds(idsToRemove);
      }
    } catch (e) {
      _log.error('queueRemove failed', e);
    }
  }

  @override
  Future<void> queueReorder(int oldIndex, int newIndex) async {
    if (kIsWeb) return;
    if (!isConnected) return;
    try {
      final items = _latestQueue.items;
      if (oldIndex < 0 || oldIndex >= items.length) return;
      if (newIndex < 0 || newIndex >= items.length) return;

      final itemId = items[oldIndex].castItemId;
      final beforeItemId = newIndex < items.length
          ? items[newIndex].castItemId
          : null;
      await GoogleCastRemoteMediaClient.instance.queueReorderItems(
        itemsIds: [itemId],
        beforeItemWithId: beforeItemId,
      );
    } catch (e) {
      _log.error('queueReorder failed', e);
    }
  }

  @override
  Future<void> queueClear() async {
    if (kIsWeb) return;
    if (!isConnected) return;
    try {
      final ids = _latestQueue.items.map((i) => i.castItemId).toList();
      if (ids.isNotEmpty) {
        await GoogleCastRemoteMediaClient.instance.queueRemoveItemsWithIds(ids);
      }
    } catch (e) {
      _log.error('queueClear failed', e);
    }
  }

  @override
  Future<void> queueJumpTo(int index) async {
    if (kIsWeb) return;
    if (!isConnected) return;
    try {
      final items = _latestQueue.items;
      if (index < 0 || index >= items.length) return;
      await GoogleCastRemoteMediaClient.instance
          .queueJumpToItemWithId(items[index].castItemId);
    } catch (e) {
      _log.error('queueJumpTo failed', e);
    }
  }

  @override
  Future<void> queueNext() async {
    if (kIsWeb) return;
    if (!isConnected) return;
    try {
      await GoogleCastRemoteMediaClient.instance.queueNextItem();
    } catch (e) {
      _log.error('queueNext failed', e);
    }
  }

  @override
  Future<void> queuePrevious() async {
    if (kIsWeb) return;
    if (!isConnected) return;
    try {
      await GoogleCastRemoteMediaClient.instance.queuePrevItem();
    } catch (e) {
      _log.error('queuePrevious failed', e);
    }
  }

  void dispose() {
    _mediaStatusSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _sessionSubscription?.cancel();
    _discoverySubscription?.cancel();
    _queueSubscription?.cancel();
    _devicesController.close();
    _mediaStatusController.close();
    _playerPositionController.close();
    _queueController.close();
    _log.info('Disposed');
  }
}

class CastDiscoveryException implements Exception {
  final String message;
  const CastDiscoveryException(this.message);
  @override
  String toString() => 'CastDiscoveryException: $message';
}

class CastConnectionException implements Exception {
  final String message;
  const CastConnectionException(this.message);
  @override
  String toString() => 'CastConnectionException: $message';
}

class CastMediaException implements Exception {
  final String message;
  const CastMediaException(this.message);
  @override
  String toString() => 'CastMediaException: $message';
}
