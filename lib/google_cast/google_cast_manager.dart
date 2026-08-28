import 'dart:async';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import '../models/cast_device.dart';
import '../models/media_item.dart';
import '../casting_core/interfaces/media_casting_interface.dart';

class GoogleCastManager implements MediaCastingInterface {
  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();

  // Keep a local reference to the latest devices list
  List<CastDevice> _latestDevices = [];

  GoogleCastManager() {
    // Map discovered Google Cast devices to our CastDevice model
    GoogleCastDiscoveryManager.instance.devicesStream.listen((devices) {
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
    });

    // Update connection state based on session state changes
    GoogleCastSessionManager.instance.currentSessionStream.listen((_) {
      final updated = _latestDevices.map((device) {
        return device.copyWith(connectionState: _getConnectionState());
      }).toList();
      _latestDevices = updated;
      _devicesController.add(updated);
    });
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
      default:
        return DeviceConnectionState.disconnected;
    }
  }

  @override
  Stream<List<CastDevice>> get discoveredDevices => _devicesController.stream;

  @override
  Future<void> startDiscovery() async {
    await GoogleCastDiscoveryManager.instance.startDiscovery();
  }

  @override
  Future<void> stopDiscovery() async {
    await GoogleCastDiscoveryManager.instance.stopDiscovery();
  }

  @override
  Future<void> connect(CastDevice device) async {
    // Find the GoogleCastDevice matching our CastDevice id
    final target = GoogleCastDiscoveryManager.instance.devices
        .firstWhere((d) => d.deviceID == device.id);
    await GoogleCastSessionManager.instance.startSessionWithDevice(target);
  }

  @override
  Future<void> disconnect() async {
    await GoogleCastSessionManager.instance.endSessionAndStopCasting();
  }

  @override
  Future<void> loadMedia(MediaItem media) async {
    final mediaInfo = GoogleCastMediaInformationIOS(
      contentId: media.thumbnailUrl,
      streamType: CastMediaStreamType.buffered,
      contentType: 'video/mp4',
      metadata: GoogleCastMovieMediaMetadata(
        title: media.title,
        subtitle: media.subtitle,
      ),
    );
    await GoogleCastRemoteMediaClient.instance.loadMedia(mediaInfo);
  }

  @override
  Future<void> play() async {
    await GoogleCastRemoteMediaClient.instance.play();
  }

  @override
  Future<void> pause() async {
    await GoogleCastRemoteMediaClient.instance.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(position: position),
    );
  }

  @override
  Future<void> setVolume(double volume) async {
    GoogleCastSessionManager.instance.setDeviceVolume(volume);
  }
}
