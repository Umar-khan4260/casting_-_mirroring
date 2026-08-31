import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/models/media_player_state.dart';
import 'package:casting_mirroring/models/cast_device.dart';
import 'package:casting_mirroring/models/media_item.dart';

void main() {
  group('MediaPlayerState', () {
    test('default values are correct', () {
      const state = MediaPlayerState();

      expect(state.status, PlayerStatus.idle);
      expect(state.media, isNull);
      expect(state.connectedDevice, isNull);
      expect(state.position, Duration.zero);
      expect(state.duration, Duration.zero);
      expect(state.isPlaying, false);
      expect(state.volume, 0.8);
      expect(state.isMuted, false);
      expect(state.isVolumeSupported, true);
      expect(state.errorMessage, isNull);
      expect(state.queue, isEmpty);
      expect(state.currentQueueIndex, 0);
    });

    group('copyWith', () {
      test('clears errorMessage when not provided', () {
        const state = MediaPlayerState(
          status: PlayerStatus.error,
          errorMessage: 'Some error',
        );

        final cleared = state.copyWith(status: PlayerStatus.idle);
        expect(cleared.errorMessage, isNull);
      });

      test('preserves errorMessage when explicitly provided', () {
        const state = MediaPlayerState(
          status: PlayerStatus.error,
          errorMessage: 'Some error',
        );

        final updated = state.copyWith(
          status: PlayerStatus.error,
          errorMessage: 'Still an error',
        );
        expect(updated.errorMessage, 'Still an error');
      });

      test('updates media and resets position', () {
        const state = MediaPlayerState(
          position: Duration(seconds: 30),
          duration: Duration(minutes: 5),
        );

        final newMedia = _FakeMediaItem(
          id: 'new',
          title: 'New',
          duration: const Duration(minutes: 10),
        );

        final updated = state.copyWith(
          media: newMedia,
          position: Duration.zero,
          duration: newMedia.duration,
        );

        expect(updated.media?.id, 'new');
        expect(updated.position, Duration.zero);
        expect(updated.duration, const Duration(minutes: 10));
      });
    });

    group('hasMedia', () {
      test('returns false when media is null', () {
        const state = MediaPlayerState();
        expect(state.hasMedia, false);
      });

      test('returns true when media is set', () {
        final state = const MediaPlayerState().copyWith(
          media: _FakeMediaItem(id: '1', title: 'Test'),
        );
        expect(state.hasMedia, true);
      });
    });

    group('isConnected', () {
      test('returns false when no device', () {
        const state = MediaPlayerState();
        expect(state.isConnected, false);
      });

      test('returns true when device is connected', () {
        const device = CastDevice(
          id: '1',
          name: 'TV',
          type: DeviceType.googleCast,
          connectionState: DeviceConnectionState.connected,
        );
        const state = MediaPlayerState(connectedDevice: device);
        expect(state.isConnected, true);
      });

      test('returns false when device is connecting', () {
        const device = CastDevice(
          id: '1',
          name: 'TV',
          type: DeviceType.googleCast,
          connectionState: DeviceConnectionState.connecting,
        );
        const state = MediaPlayerState(connectedDevice: device);
        expect(state.isConnected, false);
      });
    });

    group('hasQueue', () {
      test('returns false for empty queue', () {
        const state = MediaPlayerState();
        expect(state.hasQueue, false);
      });

      test('returns false for single item', () {
        final state = const MediaPlayerState().copyWith(
          queue: [_FakeMediaItem(id: '1', title: 'A')],
        );
        expect(state.hasQueue, false);
      });

      test('returns true for multiple items', () {
        final state = const MediaPlayerState().copyWith(
          queue: [
            _FakeMediaItem(id: '1', title: 'A'),
            _FakeMediaItem(id: '2', title: 'B'),
          ],
        );
        expect(state.hasQueue, true);
      });
    });

    group('formattedPosition', () {
      test('formats zero', () {
        const state = MediaPlayerState(position: Duration.zero);
        expect(state.formattedPosition, '00:00');
      });

      test('formats minutes and seconds', () {
        const state = MediaPlayerState(position: Duration(minutes: 5, seconds: 30));
        expect(state.formattedPosition, '05:30');
      });

      test('formats hours worth of seconds', () {
        const state = MediaPlayerState(position: Duration(hours: 1));
        expect(state.formattedPosition, '60:00');
      });
    });

    group('formattedDuration', () {
      test('formats zero', () {
        const state = MediaPlayerState(duration: Duration.zero);
        expect(state.formattedDuration, '00:00');
      });

      test('formats minutes and seconds', () {
        const state = MediaPlayerState(duration: Duration(minutes: 9, seconds: 56));
        expect(state.formattedDuration, '09:56');
      });
    });

    group('progress', () {
      test('returns 0 when duration is zero', () {
        const state = MediaPlayerState(
          position: Duration(seconds: 30),
          duration: Duration.zero,
        );
        expect(state.progress, 0);
      });

      test('returns correct fraction', () {
        const state = MediaPlayerState(
          position: Duration(seconds: 30),
          duration: Duration(seconds: 120),
        );
        expect(state.progress, closeTo(0.25, 0.01));
      });

      test('clamps to 1.0 when position exceeds duration', () {
        const state = MediaPlayerState(
          position: Duration(seconds: 200),
          duration: Duration(seconds: 120),
        );
        expect(state.progress, 1.0);
      });
    });
  });
}

class _FakeMediaItem implements MediaItem {
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

  _FakeMediaItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.thumbnailUrl = '',
    this.mediaUrl,
    this.contentType = 'video/mp4',
    this.duration = Duration.zero,
    this.type = MediaType.video,
    this.isFavorite = false,
    this.artist,
    this.album,
  }) : dateAdded = DateTime(2026, 1, 1);

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
    return _FakeMediaItem(
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
}
