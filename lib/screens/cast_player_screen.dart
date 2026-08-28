import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/media_player_state.dart';
import '../models/media_item.dart';
import '../providers/app_casting_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/states/error_state.dart';

class CastPlayerScreen extends StatefulWidget {
  final MediaItem media;

  const CastPlayerScreen({super.key, required this.media});

  @override
  State<CastPlayerScreen> createState() => _CastPlayerScreenState();
}

class _CastPlayerScreenState extends State<CastPlayerScreen> {
  late final AppCastingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppCastingController();
    if (!_controller.isCasting || _controller.state.media?.id != widget.media.id) {
      _controller.loadAndCast(widget.media);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<MediaPlayerState>(
        stream: _controller.stream,
        initialData: _controller.state,
        builder: (context, snapshot) {
          final state = snapshot.data!;

          if (state.status == PlayerStatus.error) {
            return _buildErrorState(state);
          }

          return Column(
            children: [
              _buildAppBar(state),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _buildArtwork(state),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMediaInfo(state),
                      const SizedBox(height: AppSpacing.md),
                      _buildConnectionBadge(state),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSeekBar(state),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPlaybackControls(state),
                      const SizedBox(height: AppSpacing.lg),
                      _buildVolumeControl(state),
                      const SizedBox(height: AppSpacing.lg),
                      _buildQueueButton(state),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(MediaPlayerState state) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _controller.disconnect();
              Navigator.of(context).pop();
            },
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Icon(CupertinoIcons.back, size: 22),
            ),
          ),
          const Expanded(
            child: Text(
              'Now Casting',
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildArtwork(MediaPlayerState state) {
    if (state.status == PlayerStatus.loading) {
      return _buildLoadingArtwork();
    }

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: CupertinoColors.black,
                child: Image.network(
                  state.media?.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        _typeIcon(state.media?.type),
                        color: CupertinoColors.systemGrey,
                        size: 60,
                      ),
                    );
                  },
                ),
              ),
              if (state.status == PlayerStatus.loading)
                Container(
                  color: CupertinoColors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              if (state.status == PlayerStatus.casting ||
                  state.status == PlayerStatus.paused)
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: state.isPlaying
                          ? AppColors.success
                          : AppColors.error,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.borderRadiusSm,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: CupertinoColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.isPlaying ? 'LIVE' : 'PAUSED',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingArtwork() {
    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: CupertinoActivityIndicator(
              radius: 16,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaInfo(MediaPlayerState state) {
    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Column(
        children: [
          Text(
            state.media?.title ?? '',
            style: AppTypography.heading3,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            state.media?.subtitle ?? '',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge(MediaPlayerState state) {
    if (state.connectedDevice == null) return const SizedBox.shrink();

    return Container(
      margin: AppSpacing.paddingHorizontalMd,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        border: Border.all(
          color: state.isConnected ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.tv,
            size: 16,
            color: state.isConnected ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            state.connectedDevice!.name,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: state.isConnected ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekBar(MediaPlayerState state) {
    if (state.duration.inSeconds == 0) return const SizedBox.shrink();

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: state.progress,
              onChanged: (value) {
                _controller.seekToFraction(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.formattedPosition,
                  style: AppTypography.bodySmall.copyWith(
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  state.formattedDuration,
                  style: AppTypography.bodySmall.copyWith(
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(MediaPlayerState state) {
    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: state.hasQueue ? _controller.skipPrevious : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: state.hasQueue
                    ? AppColors.surface
                    : AppColors.surface.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.backward_end_fill,
                size: 22,
                color: state.hasQueue
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          GestureDetector(
            onTap: _controller.playPause,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                state.isPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                color: CupertinoColors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          GestureDetector(
            onTap: state.hasQueue ? _controller.skipNext : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: state.hasQueue
                    ? AppColors.surface
                    : AppColors.surface.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.forward_end_fill,
                size: 22,
                color: state.hasQueue
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(MediaPlayerState state) {
    if (!state.isVolumeSupported) return const SizedBox.shrink();

    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _controller.toggleMute,
              child: Icon(
                state.isMuted
                    ? CupertinoIcons.volume_off
                    : (state.volume > 0.5
                        ? CupertinoIcons.volume_up
                        : CupertinoIcons.volume_down),
                size: 22,
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.divider,
                  thumbColor: AppColors.primary,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayColor: AppColors.primary.withValues(alpha: 0.1),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: state.isMuted ? 0 : state.volume,
                  onChanged: (value) {
                    _controller.setVolume(value);
                  },
                ),
              ),
            ),
            Icon(
              CupertinoIcons.volume_up,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueButton(MediaPlayerState state) {
    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: GestureDetector(
        onTap: () => _showQueueSheet(state),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.list_bullet,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Queue',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (state.hasQueue) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.queue.length}',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(MediaPlayerState state) {
    return Column(
      children: [
        _buildAppBar(state),
        Expanded(
          child: ErrorState(
            message: state.errorMessage ?? 'Something went wrong',
            onRetry: () {
              _controller.loadAndCast(widget.media);
            },
          ),
        ),
      ],
    );
  }

  void _showQueueSheet(MediaPlayerState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
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
                  padding: AppSpacing.paddingAllMd,
                  child: Text('Queue', style: AppTypography.heading3),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.queue.length,
                    itemBuilder: (context, index) {
                      final item = state.queue[index];
                      final isCurrent = index == state.currentQueueIndex;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        color: isCurrent
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : null,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.borderRadiusSm,
                              ),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: CupertinoColors.systemGroupedBackground,
                                child: Image.network(
                                  item.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      _typeIcon(item.type),
                                      color: CupertinoColors.systemGrey,
                                      size: 20,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: isCurrent
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isCurrent
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.artist != null)
                                    Text(
                                      item.artist!,
                                      style: AppTypography.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              const Icon(
                                CupertinoIcons.speaker_2_fill,
                                color: AppColors.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _typeIcon(MediaType? type) {
    switch (type) {
      case MediaType.video:
        return CupertinoIcons.film;
      case MediaType.music:
        return CupertinoIcons.music_note;
      case MediaType.photo:
        return CupertinoIcons.photo;
      case null:
        return CupertinoIcons.play;
    }
  }
}
