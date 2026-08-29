import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import '../models/cast_device.dart';
import '../models/cast_queue_state.dart';
import '../models/media_item.dart';
import '../casting_core/interfaces/media_casting_interface.dart';

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
    } catch (e) {
      debugPrint('GoogleCastManager: failed to initialize: $e');
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
        },
        onError: (e) {
          debugPrint('GoogleCastManager: discovery stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('GoogleCastManager: failed to init discovery listener: $e');
    }

    try {
      _sessionSubscription =
          GoogleCastSessionManager.instance.currentSessionStream.listen(
        (_) {
          final updated = _latestDevices.map((device) {
            return device.copyWith(connectionState: _getConnectionState());
          }).toList();
          _latestDevices = updated;
          _devicesController.add(updated);

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
          debugPrint('GoogleCastManager: session stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('GoogleCastManager: failed to init session listener: $e');
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
          debugPrint('GoogleCastManager: media status stream error: $e');
        },
      );
    } catch (e) {
      debugPrint(
          'GoogleCastManager: failed to init media status listener: $e');
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
          debugPrint('GoogleCastManager: player position stream error: $e');
        },
      );
    } catch (e) {
      debugPrint(
          'GoogleCastManager: failed to init player position listener: $e');
    }

    try {
      _queueSubscription =
          GoogleCastRemoteMediaClient.instance.queueItemsStream.listen(
        (queueItems) {
          _onQueueItemsUpdated(queueItems);
        },
        onError: (e) {
          debugPrint('GoogleCastManager: queue stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('GoogleCastManager: failed to init queue listener: $e');
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
    } catch (e) {
      debugPrint('GoogleCastManager: startDiscovery failed: $e');
    }
  }

  @override
  Future<void> stopDiscovery() async {
    if (kIsWeb) return;
    try {
      await GoogleCastDiscoveryManager.instance.stopDiscovery();
    } catch (e) {
      debugPrint('GoogleCastManager: stopDiscovery failed: $e');
    }
  }

  @override
  Future<void> connect(CastDevice device) async {
    if (kIsWeb) return;
    try {
      final target = GoogleCastDiscoveryManager.instance.devices
          .firstWhere((d) => d.deviceID == device.id);
      await GoogleCastSessionManager.instance.startSessionWithDevice(target);
    } catch (e) {
      debugPrint('GoogleCastManager: connect failed: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    if (kIsWeb) return;
    try {
      await GoogleCastSessionManager.instance.endSessionAndStopCasting();
    } catch (e) {
      debugPrint('GoogleCastManager: disconnect failed: $e');
    }
  }

  @override
  Future<void> loadMedia(MediaItem media) async {
    if (kIsWeb) return;
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

    await GoogleCastRemoteMediaClient.instance.loadMedia(
      mediaInfo,
      autoPlay: true,
    );
  }

  @override
  Future<void> play() async {
    if (kIsWeb) return;
    try {
      await GoogleCastRemoteMediaClient.instance.play();
    } catch (e) {
      debugPrint('GoogleCastManager: play failed: $e');
    }
  }

  @override
  Future<void> pause() async {
    if (kIsWeb) return;
    try {
      await GoogleCastRemoteMediaClient.instance.pause();
    } catch (e) {
      debugPrint('GoogleCastManager: pause failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    if (kIsWeb) return;
    try {
      await GoogleCastRemoteMediaClient.instance.stop();
    } catch (e) {
      debugPrint('GoogleCastManager: stop failed: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    if (kIsWeb) return;
    try {
      await GoogleCastRemoteMediaClient.instance.seek(
        GoogleCastMediaSeekOption(position: position),
      );
    } catch (e) {
      debugPrint('GoogleCastManager: seek failed: $e');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    if (kIsWeb) return;
    try {
      GoogleCastSessionManager.instance
          .setDeviceVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('GoogleCastManager: setVolume failed: $e');
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
      debugPrint('GoogleCastManager: queueLoad failed: $e');
    }
  }

  @override
  Future<void> queueInsert(List<MediaItem> items) async {
    if (kIsWeb || items.isEmpty) return;
    try {
      final queueItems = items.map(_mediaToQueueItem).toList();
      await GoogleCastRemoteMediaClient.instance.queueInsertItems(queueItems);
    } catch (e) {
      debugPrint('GoogleCastManager: queueInsert failed: $e');
    }
  }

  @override
  Future<void> queueInsertAndPlay(MediaItem item) async {
    if (kIsWeb) return;
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
      debugPrint('GoogleCastManager: queueInsertAndPlay failed: $e');
    }
  }

  @override
  Future<void> queueRemove(List<int> indices) async {
    if (kIsWeb || indices.isEmpty) return;
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
      debugPrint('GoogleCastManager: queueRemove failed: $e');
    }
  }

  @override
  Future<void> queueReorder(int oldIndex, int newIndex) async {
    if (kIsWeb) return;
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
      debugPrint('GoogleCastManager: queueReorder failed: $e');
    }
  }

  @override
  Future<void> queueClear() async {
    if (kIsWeb) return;
    try {
      final ids = _latestQueue.items.map((i) => i.castItemId).toList();
      if (ids.isNotEmpty) {
        await GoogleCastRemoteMediaClient.instance.queueRemoveItemsWithIds(ids);
      }
    } catch (e) {
      debugPrint('GoogleCastManager: queueClear failed: $e');
    }
  }

  @override
  Future<void> queueJumpTo(int index) async {
    if (kIsWeb) return;
    try {
      final items = _latestQueue.items;
      if (index < 0 || index >= items.length) return;
      await GoogleCastRemoteMediaClient.instance
          .queueJumpToItemWithId(items[index].castItemId);
    } catch (e) {
      debugPrint('GoogleCastManager: queueJumpTo failed: $e');
    }
  }

  @override
  Future<void> queueNext() async {
    if (kIsWeb) return;
    try {
      await GoogleCastRemoteMediaClient.instance.queueNextItem();
    } catch (e) {
      debugPrint('GoogleCastManager: queueNext failed: $e');
    }
  }

  @override
  Future<void> queuePrevious() async {
    if (kIsWeb) return;
    try {
      await GoogleCastRemoteMediaClient.instance.queuePrevItem();
    } catch (e) {
      debugPrint('GoogleCastManager: queuePrevious failed: $e');
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
  }
}
