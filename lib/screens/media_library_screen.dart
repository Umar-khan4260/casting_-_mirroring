import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/cards/video_media_card.dart';
import '../widgets/cards/music_media_card.dart';
import '../widgets/cards/photo_media_card.dart';
import '../widgets/states/empty_state.dart';
import '../services/local_media_picker.dart';
import '../services/local_media_store.dart';
import 'media_detail_screen.dart';

enum MediaCategory { all, videos, photos, music, recent, favorites }

class MediaLibraryScreen extends StatefulWidget {
  final LocalMediaStore mediaStore;

  const MediaLibraryScreen({super.key, required this.mediaStore});

  @override
  State<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends State<MediaLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  MediaCategory _selectedCategory = MediaCategory.all;
  MediaSortOption _sortOption = MediaSortOption.title;
  bool _sortAscending = true;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    widget.mediaStore.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    widget.mediaStore.removeListener(_onStoreChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  List<MediaItem> get _filteredMedia {
    List<MediaItem> items;

    switch (_selectedCategory) {
      case MediaCategory.all:
        items = List.from(widget.mediaStore.items);
        break;
      case MediaCategory.videos:
        items = widget.mediaStore.videos;
        break;
      case MediaCategory.photos:
        items = widget.mediaStore.photos;
        break;
      case MediaCategory.music:
        items = widget.mediaStore.music;
        break;
      case MediaCategory.recent:
        items = widget.mediaStore.recentlyAdded(days: 7);
        break;
      case MediaCategory.favorites:
        items = widget.mediaStore.favorites;
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((m) {
        return m.title.toLowerCase().contains(query) ||
            m.subtitle.toLowerCase().contains(query) ||
            (m.artist?.toLowerCase().contains(query) ?? false) ||
            (m.album?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    switch (_sortOption) {
      case MediaSortOption.title:
        items.sort((a, b) => _sortAscending
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title));
        break;
      case MediaSortOption.dateAdded:
        items.sort((a, b) => _sortAscending
            ? a.dateAdded.compareTo(b.dateAdded)
            : b.dateAdded.compareTo(a.dateAdded));
        break;
      case MediaSortOption.duration:
        items.sort((a, b) => _sortAscending
            ? a.duration.compareTo(b.duration)
            : b.duration.compareTo(a.duration));
        break;
      case MediaSortOption.type:
        items.sort((a, b) => _sortAscending
            ? a.type.index.compareTo(b.type.index)
            : b.type.index.compareTo(a.type.index));
        break;
    }

    return items;
  }

  void _openMediaDetail(MediaItem media) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => MediaDetailScreen(
          media: media,
          mediaStore: widget.mediaStore,
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.borderRadiusMd),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Sort By',
                    style: AppTypography.heading3,
                  ),
                ),
                _buildSortOption('Title', MediaSortOption.title),
                _buildSortOption('Date Added', MediaSortOption.dateAdded),
                _buildSortOption('Duration', MediaSortOption.duration),
                _buildSortOption('Type', MediaSortOption.type),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: AppSpacing.paddingHorizontalMd,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: AppSpacing.paddingVerticalMd,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.borderRadiusSm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _sortAscending
                                ? CupertinoIcons.arrow_up
                                : CupertinoIcons.arrow_down,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _sortAscending ? 'Ascending' : 'Descending',
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, MediaSortOption option) {
    final isSelected = _sortOption == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_sortOption == option) {
            _sortAscending = !_sortAscending;
          } else {
            _sortOption = option;
            _sortAscending = true;
          }
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTypography.bodyLarge),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = _filteredMedia;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        centerTitle: true,
        title: _isSearchActive
            ? null
            : Text(
                'Media Library',
                style: AppTypography.heading3.copyWith(fontSize: 18),
              ),
        leading: _isSearchActive
            ? IconButton(
                icon: const Icon(CupertinoIcons.back, size: 22),
                onPressed: () {
                  setState(() {
                    _isSearchActive = false;
                    _searchQuery = '';
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                  });
                },
              )
            : null,
        actions: [
          if (!_isSearchActive)
            IconButton(
              icon: const Icon(CupertinoIcons.search, size: 22),
              onPressed: () {
                setState(() {
                  _isSearchActive = true;
                });
                _searchFocusNode.requestFocus();
              },
            ),
          if (!_isSearchActive)
            IconButton(
              icon: const Icon(CupertinoIcons.sort_down, size: 22),
              onPressed: _showSortSheet,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchActive)
            Container(
              color: CupertinoColors.systemBackground,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: CupertinoSearchTextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                placeholder: 'Search media...',
                style: AppTypography.bodyLarge,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          _buildAddMediaButtons(),
          Container(
            height: 52,
            color: CupertinoColors.systemBackground,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: MediaCategory.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final cat = MediaCategory.values[index];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.borderRadiusSm + 4),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _categoryLabel(cat),
                      style: AppTypography.bodyMedium.copyWith(
                        color: isSelected
                            ? CupertinoColors.white
                            : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 1,
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
          Expanded(
            child: media.isEmpty
                ? _buildEmptyState()
                : _selectedCategory == MediaCategory.photos
                    ? _buildPhotoGrid(media)
                    : _buildMediaList(media),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(MediaCategory cat) {
    switch (cat) {
      case MediaCategory.all:
        return 'All';
      case MediaCategory.videos:
        return 'Videos';
      case MediaCategory.photos:
        return 'Photos';
      case MediaCategory.music:
        return 'Music';
      case MediaCategory.recent:
        return 'Recently Added';
      case MediaCategory.favorites:
        return 'Favorites';
    }
  }

  Widget _buildEmptyState() {
    String title;
    String message;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      title = 'No Results Found';
      message = 'No media matches "$_searchQuery". Try a different search.';
      icon = CupertinoIcons.search;
    } else {
      switch (_selectedCategory) {
        case MediaCategory.videos:
          title = 'No Videos';
          message = 'Tap the button above to pick videos from your iPhone.';
          icon = CupertinoIcons.film;
          break;
        case MediaCategory.photos:
          title = 'No Photos';
          message = 'Tap the button above to pick photos from your iPhone.';
          icon = CupertinoIcons.photo;
          break;
        case MediaCategory.music:
          title = 'No Music';
          message = 'Tap the button above to pick audio from your iPhone.';
          icon = CupertinoIcons.music_note;
          break;
        case MediaCategory.recent:
          title = 'No Recent Media';
          message = 'No media has been added in the last 7 days.';
          icon = CupertinoIcons.clock;
          break;
        case MediaCategory.favorites:
          title = 'No Favorites';
          message = 'Tap the heart icon on any media to add it to favorites.';
          icon = CupertinoIcons.heart;
          break;
        case MediaCategory.all:
          title = 'Media Library Empty';
          message = 'Pick videos, photos, or audio from your iPhone to get started.';
          icon = CupertinoIcons.play_circle;
          break;
      }
    }

    return EmptyState(title: title, message: message, icon: icon);
  }

  Widget _buildMediaList(List<MediaItem> media) {
    return ListView.builder(
      padding: AppSpacing.paddingAllMd,
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        switch (item.type) {
          case MediaType.video:
            return VideoMediaCard(
              media: item,
              onTap: () => _openMediaDetail(item),
            );
          case MediaType.music:
            return MusicMediaCard(
              media: item,
              onTap: () => _openMediaDetail(item),
            );
          case MediaType.photo:
            return PhotoMediaCard(
              media: item,
              onTap: () => _openMediaDetail(item),
            );
        }
      },
    );
  }

  Widget _buildPhotoGrid(List<MediaItem> media) {
    return GridView.builder(
      padding: AppSpacing.paddingAllMd,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        return PhotoMediaCard(
          media: item,
          onTap: () => _openMediaDetail(item),
        );
      },
    );
  }

  Widget _buildAddMediaButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPickButton(
              icon: CupertinoIcons.video_camera,
              label: 'Video',
              color: AppColors.primary,
              onTap: _pickVideo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildPickButton(
              icon: CupertinoIcons.photo_camera,
              label: 'Photo',
              color: AppColors.secondary,
              onTap: _pickPhoto,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildPickButton(
              icon: CupertinoIcons.music_note,
              label: 'Audio',
              color: AppColors.success,
              onTap: _pickAudio,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: CupertinoColors.white,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final picked = await LocalMediaPicker.pickVideo();
    if (picked == null) return;

    final mediaItem = LocalMediaPicker.toMediaItem(picked);
    await widget.mediaStore.add(mediaItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added: ${mediaItem.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await LocalMediaPicker.pickPhoto();
    if (picked == null) return;

    final mediaItem = LocalMediaPicker.toMediaItem(picked);
    await widget.mediaStore.add(mediaItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added: ${mediaItem.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _pickAudio() async {
    final picked = await LocalMediaPicker.pickAudio();
    if (picked == null) return;

    final mediaItem = LocalMediaPicker.toMediaItem(picked);
    await widget.mediaStore.add(mediaItem);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added: ${mediaItem.title}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
