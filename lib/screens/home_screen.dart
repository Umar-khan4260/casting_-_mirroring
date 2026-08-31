import 'package:flutter/cupertino.dart';
import '../providers/app_casting_controller.dart';
import '../models/media_item.dart';
import '../models/media_player_state.dart';
import '../services/local_media_store.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart';
import '../widgets/cards/action_card.dart';
import '../widgets/cards/connected_device_card.dart';
import 'cast_player_screen.dart';
import 'screen_mirror_screen.dart';

class HomeScreen extends StatelessWidget {
  final LocalMediaStore mediaStore;
  final VoidCallback? onSwitchToDevices;
  final VoidCallback? onSwitchToMedia;

  const HomeScreen({
    super.key,
    required this.mediaStore,
    this.onSwitchToDevices,
    this.onSwitchToMedia,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppCastingController(),
      builder: (context, _) {
        final controller = AppCastingController();
        final playerState = controller.state;
        final isConnected = playerState.isConnected;
        final connectedDevice = playerState.connectedDevice;
        final recentMedia = mediaStore.recentlyAdded(days: 7);

        return CupertinoPageScaffold(
          backgroundColor: AppColors.background,
          navigationBar: const CupertinoNavigationBar(
            middle: Text('Casting App'),
            backgroundColor: AppColors.surface,
            border: Border(),
          ),
          child: SafeArea(
            child: ListView(
              padding: AppSpacing.paddingAllLg,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  isConnected ? 'Connected Device' : 'No Device Connected',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                ConnectedDeviceCard(
                  device: connectedDevice,
                  onSelectDevice: onSwitchToDevices ?? () {},
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('What do you want to do?', style: AppTypography.heading3),
                const SizedBox(height: AppSpacing.md),
                ActionCard(
                  title: 'Cast Media',
                  subtitle: isConnected
                      ? 'Play videos, photos and music'
                      : 'Connect to a device first',
                  icon: CupertinoIcons.play_rectangle,
                  iconColor: AppColors.primary,
                  onTap: isConnected
                      ? (onSwitchToMedia ?? () {})
                      : (onSwitchToDevices ?? () {}),
                ),
                ActionCard(
                  title: 'Mirror Screen',
                  subtitle: 'AirPlay media routing & screen mirroring guide',
                  icon: CupertinoIcons.device_phone_portrait,
                  iconColor: AppColors.secondary,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => const ScreenMirrorScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                if (playerState.hasQueue) ...[
                  Text('Now Playing', style: AppTypography.heading3),
                  const SizedBox(height: AppSpacing.md),
                  _NowPlayingCard(
                    playerState: playerState,
                    onTap: () => _openFullPlayer(context, playerState),
                  ),
                ] else ...[
                  Text('Recent Media', style: AppTypography.heading3),
                  const SizedBox(height: AppSpacing.md),
                  if (recentMedia.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 40,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No recent media',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add media to see it here',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentMedia.length,
                        itemBuilder: (context, index) {
                          final media = recentMedia[index];
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: AppSpacing.md),
                            child: _MediaCardHorizontal(
                              media: media,
                              onTap: isConnected
                                  ? () => controller.loadAndCast(media)
                                  : () {},
                            ),
                          );
                        },
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullPlayer(BuildContext context, MediaPlayerState state) {
    if (state.media == null) return;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => CastPlayerScreen(media: state.media!),
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final MediaPlayerState playerState;
  final VoidCallback onTap;

  const _NowPlayingCard({required this.playerState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final media = playerState.media;
    if (media == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingAllMd,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              child: Image.network(
                media.thumbnailUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    child: const Icon(
                      CupertinoIcons.music_note,
                      color: CupertinoColors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    style: AppTypography.bodyLarge.copyWith(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    playerState.isPlaying ? 'Playing' : 'Paused',
                    style: AppTypography.bodySmall.copyWith(
                      color: CupertinoColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              playerState.isPlaying
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCardHorizontal extends StatelessWidget {
  final MediaItem media;
  final VoidCallback onTap;

  const _MediaCardHorizontal({required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: AppColors.background,
                child: Image.network(
                  media.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        CupertinoIcons.photo,
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.paddingAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    media.subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
