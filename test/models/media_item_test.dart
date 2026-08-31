import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/models/media_item.dart';

void main() {
  group('MediaItem', () {
    test('default values are correct', () {
      final item = MediaItem(
        id: '1',
        title: 'Test',
        subtitle: 'Sub',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        type: MediaType.video,
        dateAdded: DateTime(2026, 1, 1),
      );

      expect(item.id, '1');
      expect(item.title, 'Test');
      expect(item.subtitle, 'Sub');
      expect(item.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(item.mediaUrl, isNull);
      expect(item.contentType, 'video/mp4');
      expect(item.duration, Duration.zero);
      expect(item.type, MediaType.video);
      expect(item.isFavorite, false);
      expect(item.artist, isNull);
      expect(item.album, isNull);
    });

    group('copyWith', () {
      test('returns copy with updated fields', () {
        final item = MediaItem(
          id: '1',
          title: 'Original',
          subtitle: 'Sub',
          thumbnailUrl: 'url',
          type: MediaType.video,
          dateAdded: DateTime(2026, 1, 1),
        );

        final updated = item.copyWith(title: 'Updated', isFavorite: true);
        expect(updated.id, '1');
        expect(updated.title, 'Updated');
        expect(updated.isFavorite, true);
      });

      test('copyWith no params returns identical', () {
        final item = MediaItem(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          thumbnailUrl: 'url',
          type: MediaType.music,
          dateAdded: DateTime(2026, 1, 1),
          artist: 'Artist',
          album: 'Album',
        );

        final copy = item.copyWith();
        expect(copy.id, item.id);
        expect(copy.title, item.title);
        expect(copy.artist, item.artist);
        expect(copy.album, item.album);
      });
    });

    group('formattedDuration', () {
      test('returns empty for zero duration', () {
        final item = MediaItem(
          id: '1',
          title: 'Test',
          subtitle: '',
          thumbnailUrl: '',
          type: MediaType.video,
          dateAdded: DateTime(2026, 1, 1),
          duration: Duration.zero,
        );
        expect(item.formattedDuration, '');
      });

      test('formats minutes and seconds', () {
        final item = MediaItem(
          id: '1',
          title: 'Test',
          subtitle: '',
          thumbnailUrl: '',
          type: MediaType.video,
          dateAdded: DateTime(2026, 1, 1),
          duration: Duration(minutes: 9, seconds: 56),
        );
        expect(item.formattedDuration, '9:56');
      });

      test('formats hours when present', () {
        final item = MediaItem(
          id: '1',
          title: 'Test',
          subtitle: '',
          thumbnailUrl: '',
          type: MediaType.video,
          dateAdded: DateTime(2026, 1, 1),
          duration: Duration(hours: 2, minutes: 30, seconds: 15),
        );
        expect(item.formattedDuration, '2 h 30 m');
      });
    });

    group('MediaType', () {
      test('has all expected values', () {
        expect(MediaType.values.length, 3);
        expect(MediaType.video, isNotNull);
        expect(MediaType.photo, isNotNull);
        expect(MediaType.music, isNotNull);
      });
    });
  });
}
