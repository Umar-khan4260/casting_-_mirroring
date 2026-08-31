import 'package:mocktail/mocktail.dart';
import 'package:casting_mirroring/casting_core/interfaces/media_casting_interface.dart';
import 'package:casting_mirroring/casting_core/interfaces/screen_mirroring_interface.dart';
import 'package:casting_mirroring/models/cast_device.dart';
import 'package:casting_mirroring/models/media_item.dart';
import 'package:casting_mirroring/services/device_discovery_service.dart';

class MockMediaCastingInterface extends Mock
    implements MediaCastingInterface {}

class MockScreenMirroringInterface extends Mock
    implements ScreenMirroringInterface {}

class MockDeviceDiscoveryService extends Mock
    implements DeviceDiscoveryService {}

final kTestMediaItem = TestMediaItem(
  id: 'test_1',
  title: 'Test Video',
  subtitle: 'Test Subtitle',
  mediaUrl: 'https://example.com/video.mp4',
  contentType: 'video/mp4',
  type: MediaType.video,
);

final kTestAudioItem = TestMediaItem(
  id: 'test_audio_1',
  title: 'Test Audio',
  subtitle: 'Test Artist',
  mediaUrl: 'https://example.com/audio.mp3',
  contentType: 'audio/mpeg',
  type: MediaType.music,
);

const kTestGoogleCastDevice = CastDevice(
  id: 'gc_1',
  name: 'Living Room TV',
  type: DeviceType.googleCast,
  connectionState: DeviceConnectionState.disconnected,
  supportsMediaCasting: true,
  supportsScreenMirroring: false,
);

const kTestConnectedGoogleCastDevice = CastDevice(
  id: 'gc_1',
  name: 'Living Room TV',
  type: DeviceType.googleCast,
  connectionState: DeviceConnectionState.connected,
  supportsMediaCasting: true,
  supportsScreenMirroring: false,
);

const kTestAirPlayDevice = CastDevice(
  id: 'airplay_system',
  name: 'Apple TV',
  type: DeviceType.appleAirPlay,
  connectionState: DeviceConnectionState.disconnected,
  mirroringConnectionState: DeviceConnectionState.connected,
  supportsMediaCasting: false,
  supportsScreenMirroring: true,
);

const kTestDualCapabilityDevice = CastDevice(
  id: 'gc_2',
  name: 'Bedroom TV',
  type: DeviceType.googleCast,
  connectionState: DeviceConnectionState.connected,
  mirroringConnectionState: DeviceConnectionState.connected,
  supportsMediaCasting: true,
  supportsScreenMirroring: true,
);

class TestMediaItem implements MediaItem {
  @override
  final String id;
  @override
  final String title;
  @override
  final String subtitle;
  @override
  final String thumbnailUrl;
  @override
  final String? mediaUrl;
  @override
  final String contentType;
  @override
  final Duration duration;
  @override
  final MediaType type;
  @override
  final DateTime dateAdded;
  @override
  final bool isFavorite;
  @override
  final String? artist;
  @override
  final String? album;

  TestMediaItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.thumbnailUrl = '',
    this.mediaUrl,
    this.contentType = 'video/mp4',
    this.duration = Duration.zero,
    this.type = MediaType.video,
    DateTime? dateAdded,
    this.isFavorite = false,
    this.artist,
    this.album,
  }) : dateAdded = dateAdded ?? DateTime(2026, 1, 1);

  @override
  String get formattedDuration => '';

  @override
  MediaItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? thumbnailUrl,
    String? mediaUrl,
    String? contentType,
    Duration? duration,
    MediaType? type,
    DateTime? dateAdded,
    bool? isFavorite,
    String? artist,
    String? album,
  }) {
    return TestMediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      contentType: contentType ?? this.contentType,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      artist: artist ?? this.artist,
      album: album ?? this.album,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'thumbnailUrl': thumbnailUrl,
      'mediaUrl': mediaUrl,
      'contentType': contentType,
      'durationMs': duration.inMilliseconds,
      'type': type.index,
      'dateAdded': dateAdded.toIso8601String(),
      'isFavorite': isFavorite,
      'artist': artist,
      'album': album,
    };
  }

  factory TestMediaItem.fromMap(Map<String, dynamic> map) {
    return TestMediaItem(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      mediaUrl: map['mediaUrl'] as String?,
      contentType: map['contentType'] as String? ?? 'video/mp4',
      duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
      type: MediaType.values[map['type'] as int? ?? 0],
      dateAdded: DateTime.parse(map['dateAdded'] as String),
      isFavorite: map['isFavorite'] as bool? ?? false,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
    );
  }
}
