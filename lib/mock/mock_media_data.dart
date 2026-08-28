import '../models/media_item.dart';

class MockMediaData {
  MockMediaData._();

  static final DateTime _now = DateTime.now();

  static final List<MediaItem> allMedia = [
    MediaItem(
      id: 'v1',
      title: 'Nature Documentary',
      subtitle: '4K UHD • 1h 45m',
      thumbnailUrl: 'https://picsum.photos/seed/nature/600/340',
      duration: const Duration(hours: 1, minutes: 45),
      type: MediaType.video,
      dateAdded: _now.subtract(const Duration(days: 1)),
      isFavorite: true,
    ),
    MediaItem(
      id: 'v2',
      title: 'City Timelapse',
      subtitle: '1080p • 12m 30s',
      thumbnailUrl: 'https://picsum.photos/seed/city/600/340',
      duration: const Duration(minutes: 12, seconds: 30),
      type: MediaType.video,
      dateAdded: _now.subtract(const Duration(days: 2)),
    ),
    MediaItem(
      id: 'v3',
      title: 'Cooking Masterclass',
      subtitle: '720p • 28m 15s',
      thumbnailUrl: 'https://picsum.photos/seed/cooking/600/340',
      duration: const Duration(minutes: 28, seconds: 15),
      type: MediaType.video,
      dateAdded: _now.subtract(const Duration(days: 3)),
    ),
    MediaItem(
      id: 'v4',
      title: 'Space Exploration',
      subtitle: '4K UHD • 2h 10m',
      thumbnailUrl: 'https://picsum.photos/seed/space/600/340',
      duration: const Duration(hours: 2, minutes: 10),
      type: MediaType.video,
      dateAdded: _now.subtract(const Duration(days: 4)),
      isFavorite: true,
    ),
    MediaItem(
      id: 'v5',
      title: 'Ocean Waves ASMR',
      subtitle: '1080p • 45m 00s',
      thumbnailUrl: 'https://picsum.photos/seed/ocean/600/340',
      duration: const Duration(minutes: 45),
      type: MediaType.video,
      dateAdded: _now.subtract(const Duration(days: 5)),
    ),
    MediaItem(
      id: 'v6',
      title: 'Travel Vlog: Tokyo',
      subtitle: '1080p • 18m 42s',
      thumbnailUrl: 'https://picsum.photos/seed/tokyo/600/340',
      duration: const Duration(minutes: 18, seconds: 42),
      type: MediaType.video,
      dateAdded: _now.subtract(const Duration(days: 1)),
    ),
    MediaItem(
      id: 'v7',
      title: 'Fitness Workout',
      subtitle: '720p • 35m 20s',
      thumbnailUrl: 'https://picsum.photos/seed/fitness/600/340',
      duration: const Duration(minutes: 35, seconds: 20),
      type: MediaType.video,
      dateAdded: _now.subtract(const Duration(days: 8)),
    ),
    MediaItem(
      id: 'v8',
      title: 'Music Festival Highlights',
      subtitle: '4K UHD • 1h 12m',
      thumbnailUrl: 'https://picsum.photos/seed/festival/600/340',
      duration: const Duration(hours: 1, minutes: 12),
      type: MediaType.video,
      dateAdded: _now.subtract(const Duration(days: 6)),
      isFavorite: true,
    ),
    MediaItem(
      id: 'm1',
      title: 'Midnight Dreams',
      subtitle: 'Chill Beats • 3:42',
      thumbnailUrl: 'https://picsum.photos/seed/album1/300/300',
      duration: const Duration(minutes: 3, seconds: 42),
      type: MediaType.music,
      dateAdded: _now.subtract(const Duration(days: 1)),
      artist: 'Luna Echo',
      album: 'Nocturnal',
    ),
    MediaItem(
      id: 'm2',
      title: 'Summer Vibes',
      subtitle: 'Indie Pop • 4:15',
      thumbnailUrl: 'https://picsum.photos/seed/album2/300/300',
      duration: const Duration(minutes: 4, seconds: 15),
      type: MediaType.music,
      dateAdded: _now.subtract(const Duration(days: 2)),
      artist: 'The Wanderers',
      album: 'Golden Hour',
    ),
    MediaItem(
      id: 'm3',
      title: 'Neon Lights',
      subtitle: 'Synthwave • 5:08',
      thumbnailUrl: 'https://picsum.photos/seed/album3/300/300',
      duration: const Duration(minutes: 5, seconds: 8),
      type: MediaType.music,
      dateAdded: _now.subtract(const Duration(days: 3)),
      artist: 'RetroWave',
      album: 'Digital Sunset',
    ),
    MediaItem(
      id: 'm4',
      title: 'Ocean Breeze',
      subtitle: 'Ambient • 6:30',
      thumbnailUrl: 'https://picsum.photos/seed/album4/300/300',
      duration: const Duration(minutes: 6, seconds: 30),
      type: MediaType.music,
      dateAdded: _now.subtract(const Duration(days: 4)),
      artist: 'Calm Waves',
      album: 'Seaside',
    ),
    MediaItem(
      id: 'm5',
      title: 'Electric Soul',
      subtitle: 'R&B • 3:55',
      thumbnailUrl: 'https://picsum.photos/seed/album5/300/300',
      duration: const Duration(minutes: 3, seconds: 55),
      type: MediaType.music,
      dateAdded: _now.subtract(const Duration(days: 1)),
      artist: 'Aria Blue',
      album: 'Spectrum',
      isFavorite: true,
    ),
    MediaItem(
      id: 'm6',
      title: 'Morning Coffee Jazz',
      subtitle: 'Jazz • 4:48',
      thumbnailUrl: 'https://picsum.photos/seed/album6/300/300',
      duration: const Duration(minutes: 4, seconds: 48),
      type: MediaType.music,
      dateAdded: _now.subtract(const Duration(days: 6)),
      artist: 'Smooth Trio',
      album: 'Cafe Sessions',
    ),
    MediaItem(
      id: 'm7',
      title: 'Mountain Sunrise',
      subtitle: 'Classical • 8:22',
      thumbnailUrl: 'https://picsum.photos/seed/album7/300/300',
      duration: const Duration(minutes: 8, seconds: 22),
      type: MediaType.music,
      dateAdded: _now.subtract(const Duration(days: 7)),
      artist: 'Vienna Strings',
      album: 'Dawn',
    ),
    MediaItem(
      id: 'm8',
      title: 'Deep Focus',
      subtitle: 'Lo-fi • 5:15',
      thumbnailUrl: 'https://picsum.photos/seed/album8/300/300',
      duration: const Duration(minutes: 5, seconds: 15),
      type: MediaType.music,
      dateAdded: _now.subtract(const Duration(days: 2)),
      artist: 'Chillhop',
      album: 'Focus Beats',
      isFavorite: true,
    ),
    MediaItem(
      id: 'p1',
      title: 'Sunset at the Beach',
      subtitle: 'Photo • 2.4 MB',
      thumbnailUrl: 'https://picsum.photos/seed/beach/600/400',
      type: MediaType.photo,
      dateAdded: _now.subtract(const Duration(days: 1)),
      isFavorite: true,
    ),
    MediaItem(
      id: 'p2',
      title: 'Mountain Landscape',
      subtitle: 'Photo • 3.1 MB',
      thumbnailUrl: 'https://picsum.photos/seed/mountain/600/400',
      type: MediaType.photo,
      dateAdded: _now.subtract(const Duration(days: 2)),
    ),
    MediaItem(
      id: 'p3',
      title: 'Family Portrait',
      subtitle: 'Photo • 1.8 MB',
      thumbnailUrl: 'https://picsum.photos/seed/family/600/400',
      type: MediaType.photo,
      dateAdded: _now.subtract(const Duration(days: 3)),
      isFavorite: true,
    ),
    MediaItem(
      id: 'p4',
      title: 'City Skyline',
      subtitle: 'Photo • 4.2 MB',
      thumbnailUrl: 'https://picsum.photos/seed/skyline/600/400',
      type: MediaType.photo,
      dateAdded: _now.subtract(const Duration(days: 4)),
    ),
    MediaItem(
      id: 'p5',
      title: 'Autumn Forest',
      subtitle: 'Photo • 2.9 MB',
      thumbnailUrl: 'https://picsum.photos/seed/forest/600/400',
      type: MediaType.photo,
      dateAdded: _now.subtract(const Duration(days: 5)),
    ),
    MediaItem(
      id: 'p6',
      title: 'Street Photography',
      subtitle: 'Photo • 1.5 MB',
      thumbnailUrl: 'https://picsum.photos/seed/street/600/400',
      type: MediaType.photo,
      dateAdded: _now.subtract(const Duration(days: 1)),
    ),
    MediaItem(
      id: 'p7',
      title: 'Northern Lights',
      subtitle: 'Photo • 5.6 MB',
      thumbnailUrl: 'https://picsum.photos/seed/aurora/600/400',
      type: MediaType.photo,
      dateAdded: _now.subtract(const Duration(days: 8)),
    ),
    MediaItem(
      id: 'p8',
      title: 'Underwater Reef',
      subtitle: 'Photo • 3.3 MB',
      thumbnailUrl: 'https://picsum.photos/seed/reef/600/400',
      type: MediaType.photo,
      dateAdded: _now.subtract(const Duration(days: 9)),
    ),
  ];

  static List<MediaItem> get videos =>
      allMedia.where((m) => m.type == MediaType.video).toList();

  static List<MediaItem> get photos =>
      allMedia.where((m) => m.type == MediaType.photo).toList();

  static List<MediaItem> get music =>
      allMedia.where((m) => m.type == MediaType.music).toList();

  static List<MediaItem> get favorites =>
      allMedia.where((m) => m.isFavorite).toList();

  static List<MediaItem> recentlyAdded({int days = 3}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return allMedia.where((m) => m.dateAdded.isAfter(cutoff)).toList()
      ..sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
  }
}
