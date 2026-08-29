import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/cast_queue_state.dart';
import '../models/media_item.dart';
import '../providers/app_casting_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late final AppCastingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppCastingController();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Queue'),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, size: 22),
        ),
        trailing: _controller.queueState.isNotEmpty
            ? GestureDetector(
                onTap: _showClearConfirm,
                child: Text(
                  'Clear',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: StreamBuilder<CastQueueState>(
          stream: _controller.queueStream,
          initialData: _controller.queueState,
          builder: (context, snapshot) {
            final queue = snapshot.data!;
            if (queue.isEmpty) {
              return _buildEmptyState();
            }
            return _buildQueueList(queue);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllLg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.list_bullet,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Queue is Empty',
              style: AppTypography.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cast media to see items in the queue',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(CastQueueState queue) {
    return Column(
      children: [
        _buildQueueHeader(queue),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: queue.items.length,
            onReorderItem: (int oldIndex, int newIndex) {
              _controller.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final item = queue.items[index];
              final isCurrent = index == queue.currentIndex;
              return _buildQueueItem(
                item: item,
                index: index,
                isCurrent: isCurrent,
                queue: queue,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQueueHeader(CastQueueState queue) {
    return Container(
      padding: AppSpacing.paddingHorizontalMd,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.music_note_list,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            queue.formattedItemCount,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (queue.repeatMode != CastRepeatMode.off)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: Text(
                _repeatModeLabel(queue.repeatMode),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueItem({
    required CastQueueItem item,
    required int index,
    required bool isCurrent,
    required CastQueueState queue,
  }) {
    final media = item.media;
    final isUpcoming = index > queue.currentIndex;

    return Dismissible(
      key: ValueKey('queue_${item.castItemId}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: AppSpacing.paddingHorizontalMd,
        color: AppColors.error,
        child: const Icon(
          CupertinoIcons.trash,
          color: CupertinoColors.white,
          size: 22,
        ),
      ),
      confirmDismiss: (_) => _showRemoveConfirm(index),
      child: GestureDetector(
        onTap: isCurrent ? null : () => _controller.jumpToQueueItem(index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              _buildItemThumbnail(media, isCurrent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isCurrent) ...[
                          Icon(
                            CupertinoIcons.speaker_2_fill,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Expanded(
                          child: Text(
                            media.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight:
                                  isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isCurrent
                                  ? AppColors.primary
                                  : isUpcoming
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _itemSubtitle(media),
                          style: AppTypography.bodySmall.copyWith(
                            color: isCurrent
                                ? AppColors.primary.withValues(alpha: 0.7)
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (media.duration.inSeconds > 0)
                          Text(
                            _formatDuration(media.duration),
                            style: AppTypography.bodySmall.copyWith(
                              fontFeatures: [const FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (!isCurrent)
                Icon(
                  CupertinoIcons.forward,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemThumbnail(MediaItem media, bool isCurrent) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        color: CupertinoColors.systemGrey5,
      ),
      clipBehavior: Clip.antiAlias,
      child: media.thumbnailUrl.isNotEmpty
          ? Image.network(
              media.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    _typeIcon(media.type),
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            )
          : Center(
              child: Icon(
                _typeIcon(media.type),
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
    );
  }

  String _itemSubtitle(MediaItem media) {
    final parts = <String>[];
    if (media.artist != null) parts.add(media.artist!);
    if (media.album != null) parts.add(media.album!);
    if (parts.isEmpty && media.subtitle.isNotEmpty) parts.add(media.subtitle);
    return parts.join(' - ');
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _repeatModeLabel(CastRepeatMode mode) {
    switch (mode) {
      case CastRepeatMode.off:
        return '';
      case CastRepeatMode.single:
        return 'Repeat One';
      case CastRepeatMode.all:
        return 'Repeat All';
      case CastRepeatMode.allAndShuffle:
        return 'Shuffle';
    }
  }

  IconData _typeIcon(MediaType type) {
    switch (type) {
      case MediaType.video:
        return CupertinoIcons.film;
      case MediaType.music:
        return CupertinoIcons.music_note;
      case MediaType.photo:
        return CupertinoIcons.photo;
    }
  }

  Future<bool?> _showRemoveConfirm(int index) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove from Queue'),
        content: const Text('This item will be removed from the queue.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () {
              _controller.removeFromQueue(index);
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  void _showClearConfirm() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Queue'),
        content: const Text('All items will be removed from the queue.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Clear'),
            onPressed: () {
              _controller.clearQueue();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
