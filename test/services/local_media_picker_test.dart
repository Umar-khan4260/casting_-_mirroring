import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/services/local_media_picker.dart';
import 'package:casting_mirroring/models/media_item.dart';

void main() {
  group('LocalMediaPicker', () {
    test('toMediaItem creates correct MediaItem', () {
      const picked = PickedLocalMedia(
        filePath: '/var/mobile/Containers/Data/test.mp4',
        fileName: 'test.mp4',
        fileSize: 52428800,
        duration: Duration(minutes: 5, seconds: 30),
        type: MediaType.video,
      );

      final media = LocalMediaPicker.toMediaItem(picked);

      expect(media.id, startsWith('local_'));
      expect(media.title, 'test.mp4');
      expect(media.subtitle, '50.0 MB');
      expect(media.mediaUrl, '/var/mobile/Containers/Data/test.mp4');
      expect(media.contentType, 'video/mp4');
      expect(media.duration, const Duration(minutes: 5, seconds: 30));
      expect(media.type, MediaType.video);
      expect(media.thumbnailUrl, '');
    });

    test('toMediaItem handles different file sizes', () {
      const pickedBytes = PickedLocalMedia(
        filePath: '/test.txt',
        fileName: 'test.txt',
        fileSize: 512,
        type: MediaType.video,
      );
      expect(LocalMediaPicker.toMediaItem(pickedBytes).subtitle, '512 B');

      const pickedKB = PickedLocalMedia(
        filePath: '/test.txt',
        fileName: 'test.txt',
        fileSize: 2048,
        type: MediaType.video,
      );
      expect(LocalMediaPicker.toMediaItem(pickedKB).subtitle, '2.0 KB');

      const pickedGB = PickedLocalMedia(
        filePath: '/test.txt',
        fileName: 'test.txt',
        fileSize: 2147483648,
        type: MediaType.video,
      );
      expect(LocalMediaPicker.toMediaItem(pickedGB).subtitle, '2.0 GB');
    });

    test('toMediaItem creates unique IDs', () async {
      const picked = PickedLocalMedia(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        fileSize: 1024,
      );

      final media1 = LocalMediaPicker.toMediaItem(picked);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final media2 = LocalMediaPicker.toMediaItem(picked);

      expect(media1.id, isNot(equals(media2.id)));
    });

    test('toMediaItem sets dateAdded to now', () {
      const picked = PickedLocalMedia(
        filePath: '/test.mp4',
        fileName: 'test.mp4',
        fileSize: 1024,
      );

      final before = DateTime.now();
      final media = LocalMediaPicker.toMediaItem(picked);
      final after = DateTime.now();

      expect(media.dateAdded.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(media.dateAdded.isBefore(after.add(const Duration(seconds: 1))), true);
    });
  });
}
