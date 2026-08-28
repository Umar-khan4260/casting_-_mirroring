enum MediaType { video, photo, music }

enum MediaSortOption { title, dateAdded, duration, type }

class MediaItem {
  final String id;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
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
}
