import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/media_item.dart';
import '../utils/cast_logger.dart';

const _log = CastLogger('LocalMediaPicker');

class PickedLocalMedia {
  final String filePath;
  final String fileName;
  final int fileSize;
  final Duration duration;
  final MediaType type;

  const PickedLocalMedia({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    this.duration = Duration.zero,
    this.type = MediaType.video,
  });
}

class LocalMediaPicker {
  static Future<PickedLocalMedia?> pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _log.debug('User cancelled video picker');
        return null;
      }

      final file = result.files.first;
      if (file.path == null) {
        _log.error('Picked file has no path');
        return null;
      }

      final path = file.path!;
      final fileName = _getFileName(path);
      final fileSize = file.size;
      final ext = _getExtension(path).toLowerCase();
      final type = _mediaTypeFromExtension(ext);

      _log.info('Picked video: $fileName (${_formatFileSize(fileSize)})');

      return PickedLocalMedia(
        filePath: path,
        fileName: fileName,
        fileSize: fileSize,
        type: type,
      );
    } catch (e) {
      _log.error('Failed to pick video', e);
      return null;
    }
  }

  static Future<PickedLocalMedia?> pickPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _log.debug('User cancelled photo picker');
        return null;
      }

      final file = result.files.first;
      if (file.path == null) {
        _log.error('Picked file has no path');
        return null;
      }

      final path = file.path!;
      final fileName = _getFileName(path);
      final fileSize = file.size;
      final ext = _getExtension(path).toLowerCase();
      final type = _mediaTypeFromExtension(ext);

      _log.info('Picked photo: $fileName (${_formatFileSize(fileSize)})');

      return PickedLocalMedia(
        filePath: path,
        fileName: fileName,
        fileSize: fileSize,
        type: type,
      );
    } catch (e) {
      _log.error('Failed to pick photo', e);
      return null;
    }
  }

  static Future<PickedLocalMedia?> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _log.debug('User cancelled audio picker');
        return null;
      }

      final file = result.files.first;
      if (file.path == null) {
        _log.error('Picked file has no path');
        return null;
      }

      final path = file.path!;
      final fileName = _getFileName(path);
      final fileSize = file.size;
      final ext = _getExtension(path).toLowerCase();
      final type = _mediaTypeFromExtension(ext);

      _log.info('Picked audio: $fileName (${_formatFileSize(fileSize)})');

      return PickedLocalMedia(
        filePath: path,
        fileName: fileName,
        fileSize: fileSize,
        type: type,
      );
    } catch (e) {
      _log.error('Failed to pick audio', e);
      return null;
    }
  }

  static Future<PickedLocalMedia?> pickMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        _log.debug('User cancelled media picker');
        return null;
      }

      final file = result.files.first;
      if (file.path == null) {
        _log.error('Picked file has no path');
        return null;
      }

      final path = file.path!;
      final fileName = _getFileName(path);
      final fileSize = file.size;
      final ext = _getExtension(path).toLowerCase();
      final type = _mediaTypeFromExtension(ext);

      _log.info('Picked media: $fileName (${_formatFileSize(fileSize)}, ${type.name})');

      return PickedLocalMedia(
        filePath: path,
        fileName: fileName,
        fileSize: fileSize,
        type: type,
      );
    } catch (e) {
      _log.error('Failed to pick media', e);
      return null;
    }
  }

  static MediaItem toMediaItem(PickedLocalMedia picked) {
    return MediaItem(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}_${picked.fileName.hashCode}',
      title: picked.fileName,
      subtitle: _formatFileSize(picked.fileSize),
      thumbnailUrl: '',
      mediaUrl: picked.filePath,
      contentType: _contentTypeFromExtension(_getExtension(picked.filePath)),
      duration: picked.duration,
      type: picked.type,
      dateAdded: DateTime.now(),
    );
  }

  static String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  static String _getExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot + 1);
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _contentTypeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      case 'm4v':
        return 'video/x-m4v';
      case '3gp':
        return 'video/3gpp';
      case 'ts':
        return 'video/mp2t';
      default:
        return 'video/mp4';
    }
  }

  static MediaType _mediaTypeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
      case 'm4v':
      case '3gp':
      case 'ts':
        return MediaType.video;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return MediaType.photo;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
      case 'ogg':
        return MediaType.music;
      default:
        return MediaType.video;
    }
  }
}
