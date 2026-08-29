import 'media_item.dart';

enum CastRepeatMode { off, single, all, allAndShuffle }

class CastQueueItem {
  final MediaItem media;
  final int castItemId;
  final bool isCurrentlyPlaying;

  const CastQueueItem({
    required this.media,
    required this.castItemId,
    this.isCurrentlyPlaying = false,
  });

  CastQueueItem copyWith({
    MediaItem? media,
    int? castItemId,
    bool? isCurrentlyPlaying,
  }) {
    return CastQueueItem(
      media: media ?? this.media,
      castItemId: castItemId ?? this.castItemId,
      isCurrentlyPlaying: isCurrentlyPlaying ?? this.isCurrentlyPlaying,
    );
  }
}

class CastQueueState {
  final List<CastQueueItem> items;
  final int currentIndex;
  final CastRepeatMode repeatMode;
  final bool isShuffled;

  const CastQueueState({
    this.items = const [],
    this.currentIndex = 0,
    this.repeatMode = CastRepeatMode.off,
    this.isShuffled = false,
  });

  CastQueueState copyWith({
    List<CastQueueItem>? items,
    int? currentIndex,
    CastRepeatMode? repeatMode,
    bool? isShuffled,
  }) {
    return CastQueueState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
    );
  }

  bool get hasQueue => items.length > 1;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  int get length => items.length;

  CastQueueItem? get currentItem =>
      items.isNotEmpty && currentIndex < items.length
          ? items[currentIndex]
          : null;

  List<CastQueueItem> get upcomingItems =>
      items.sublist(currentIndex + 1).toList();

  List<CastQueueItem> get previousItems =>
      items.sublist(0, currentIndex).toList();

  bool get hasNextItem => currentIndex < items.length - 1;
  bool get hasPreviousItem => currentIndex > 0;

  MediaItem? get currentMedia => currentItem?.media;

  String get formattedItemCount => '${items.length} item${items.length == 1 ? '' : 's'}';

  CastQueueItem? itemAt(int index) {
    if (index < 0 || index >= items.length) return null;
    return items[index];
  }
}
