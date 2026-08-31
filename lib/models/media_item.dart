enum MediaType { video, photo, music }

enum MediaSortOption { title, dateAdded, duration, type }

class MediaItem {
  final String id;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final String? mediaUrl;
  final String contentType;
  final Duration duration;
  final MediaType type;
  final DateTime dateAdded;
  final bool isFavorite;
  final String? artist;
  final String? album;

  const MediaItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    this.mediaUrl,
    this.contentType = 'video/mp4',
    this.duration = Duration.zero,
    required this.type,
    required this.dateAdded,
    this.isFavorite = false,
    this.artist,
    this.album,
  });

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
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      contentType: contentType ?? this.contentType,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      dateAdded: dateAdded ?? this.dateAdded,
      isFavorite: isFavorite ?? this.isFavorite,
      artist: artist ?? this.artist,
      album: album ?? this.album,
    );
  }

  String get formattedDuration {
    if (duration.inSeconds == 0) return '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours h $minutes m';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

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

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
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
