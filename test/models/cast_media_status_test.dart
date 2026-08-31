import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/casting_core/interfaces/media_casting_interface.dart';
import 'package:casting_mirroring/models/cast_queue_state.dart';
import 'package:casting_mirroring/models/media_item.dart';

void main() {
  group('CastMediaStatus', () {
    test('default values are correct', () {
      const status = CastMediaStatus();

      expect(status.isPlaying, false);
      expect(status.isPaused, false);
      expect(status.isBuffering, false);
      expect(status.isIdle, true);
      expect(status.isError, false);
      expect(status.position, Duration.zero);
      expect(status.duration, Duration.zero);
      expect(status.volume, 0.8);
      expect(status.isMuted, false);
      expect(status.contentId, isNull);
    });

    group('copyWith', () {
      test('returns copy with updated fields', () {
        const status = CastMediaStatus();
        final updated = status.copyWith(
          isPlaying: true,
          isIdle: false,
          position: const Duration(seconds: 30),
          volume: 0.5,
        );

        expect(updated.isPlaying, true);
        expect(updated.isIdle, false);
        expect(updated.position, const Duration(seconds: 30));
        expect(updated.volume, 0.5);
        expect(updated.isError, false);
      });

      test('copyWith no params returns identical', () {
        const status = CastMediaStatus(
          isPlaying: true,
          position: Duration(seconds: 10),
          volume: 0.6,
        );

        final copy = status.copyWith();
        expect(copy.isPlaying, true);
        expect(copy.position, const Duration(seconds: 10));
        expect(copy.volume, 0.6);
      });
    });

    group('state combinations', () {
      test('error state', () {
        const status = CastMediaStatus(isError: true, isIdle: true);
        expect(status.isError, true);
        expect(status.isPlaying, false);
      });

      test('buffering state', () {
        const status = CastMediaStatus(isBuffering: true);
        expect(status.isBuffering, true);
        expect(status.isPlaying, false);
      });

      test('playing state', () {
        const status = CastMediaStatus(isPlaying: true, isIdle: false);
        expect(status.isPlaying, true);
        expect(status.isIdle, false);
      });

      test('paused state', () {
        const status = CastMediaStatus(isPaused: true, isIdle: false);
        expect(status.isPaused, true);
      });
    });
  });

  group('CastQueueState', () {
    test('default values are correct', () {
      const state = CastQueueState();

      expect(state.items, isEmpty);
      expect(state.currentIndex, 0);
      expect(state.repeatMode, CastRepeatMode.off);
      expect(state.isShuffled, false);
    });

    group('hasQueue', () {
      test('returns false for empty queue', () {
        const state = CastQueueState();
        expect(state.hasQueue, false);
      });

      test('returns false for single item', () {
        final queueItem = CastQueueItem(
          media: _FakeMedia(id: 'q1', title: 'Item 1'),
          castItemId: 1,
        );
        final state = CastQueueState(items: [queueItem]);
        expect(state.hasQueue, false);
      });

      test('returns true for multiple items', () {
        final state = CastQueueState(items: [kQueueItem1, kQueueItem2]);
        expect(state.hasQueue, true);
      });
    });

    group('currentItem', () {
      test('returns null for empty queue', () {
        const state = CastQueueState();
        expect(state.currentItem, isNull);
      });

      test('returns correct item at index', () {
        final item1 = CastQueueItem(
          media: _FakeMedia(id: 'a', title: 'A'),
          castItemId: 1,
        );
        final item2 = CastQueueItem(
          media: _FakeMedia(id: 'b', title: 'B'),
          castItemId: 2,
        );

        final state = CastQueueState(items: [item1, item2], currentIndex: 1);
        expect(state.currentItem?.media.id, 'b');
      });
    });

    group('hasNextItem/hasPreviousItem', () {
      test('first item has next but no previous', () {
        final state = CastQueueState(
          items: [kQueueItem1, kQueueItem2],
          currentIndex: 0,
        );
        expect(state.hasNextItem, true);
        expect(state.hasPreviousItem, false);
      });

      test('last item has previous but no next', () {
        final state = CastQueueState(
          items: [kQueueItem1, kQueueItem2],
          currentIndex: 1,
        );
        expect(state.hasNextItem, false);
        expect(state.hasPreviousItem, true);
      });

      test('middle item has both', () {
        final state = CastQueueState(
          items: [kQueueItem1, kQueueItem2, kQueueItem1],
          currentIndex: 1,
        );
        expect(state.hasNextItem, true);
        expect(state.hasPreviousItem, true);
      });
    });

    group('itemAt', () {
      test('returns null for out of bounds', () {
        final state = CastQueueState(items: [kQueueItem1]);
        expect(state.itemAt(-1), isNull);
        expect(state.itemAt(1), isNull);
      });

      test('returns correct item', () {
        final state = CastQueueState(items: [kQueueItem1, kQueueItem2]);
        expect(state.itemAt(0)?.media.id, kQueueItem1.media.id);
        expect(state.itemAt(1)?.media.id, kQueueItem2.media.id);
      });
    });

    group('formattedItemCount', () {
      test('singular', () {
        final state = CastQueueState(items: [kQueueItem1]);
        expect(state.formattedItemCount, '1 item');
      });

      test('plural', () {
        final state = CastQueueState(items: [kQueueItem1, kQueueItem2]);
        expect(state.formattedItemCount, '2 items');
      });
    });

    group('copyWith', () {
      test('returns copy with updated fields', () {
        const state = CastQueueState();
        final updated = state.copyWith(
          items: [kQueueItem1],
          currentIndex: 0,
          repeatMode: CastRepeatMode.all,
        );

        expect(updated.items.length, 1);
        expect(updated.currentIndex, 0);
        expect(updated.repeatMode, CastRepeatMode.all);
      });
    });
  });
}

final kQueueItem1 = CastQueueItem(
  media: _FakeMedia(id: 'q1', title: 'Queue Item 1'),
  castItemId: 1,
);

final kQueueItem2 = CastQueueItem(
  media: _FakeMedia(id: 'q2', title: 'Queue Item 2'),
  castItemId: 2,
);

class _FakeMedia implements MediaItem {
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

  _FakeMedia({
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
    return _FakeMedia(
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
