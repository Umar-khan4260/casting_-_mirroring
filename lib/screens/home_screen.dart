import 'package:flutter/cupertino.dart';
import '../providers/app_casting_controller.dart';
import '../models/media_player_state.dart';
import '../mock/mock_media_data.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/cards/action_card.dart';
import '../widgets/cards/connected_device_card.dart';
import 'cast_player_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onSwitchToDevices;
  final VoidCallback? onSwitchToMedia;

  const HomeScreen({
    super.key,
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

        return CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(middle: Text('Casting App')),
          child: SafeArea(
            child: ListView(
              padding: AppSpacing.paddingAllLg,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  isConnected ? 'Connected Device' : 'No Device Connected',
                  style: AppTypography.bodyMedium.copyWith(
                    color: CupertinoColors.systemGrey,
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
                  iconColor: CupertinoColors.activeBlue,
                  onTap: isConnected
                      ? (onSwitchToMedia ?? () {})
                      : (onSwitchToDevices ?? () {}),
                ),
                ActionCard(
                  title: 'Mirror Screen',
                  subtitle: isConnected
                      ? 'Mirror your iPhone screen'
                      : 'Connect to a device first',
                  icon: CupertinoIcons.device_phone_portrait,
                  iconColor: CupertinoColors.systemPurple,
                  onTap: isConnected
                      ? () => _startScreenMirroring(context)
                      : (onSwitchToDevices ?? () {}),
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
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: MockMediaData.recentlyAdded().length,
                      itemBuilder: (context, index) {
                        final media = MockMediaData.recentlyAdded()[index];
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

  void _startScreenMirroring(BuildContext context) {
    final controller = AppCastingController();
    final connectedDevice = controller.state.connectedDevice;
    if (connectedDevice != null) {
      controller.startScreenMirroring(connectedDevice);
    }
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
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.activeBlue.withAlpha(76),
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
                    color: CupertinoColors.white.withAlpha(26),
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
                      color: CupertinoColors.white.withAlpha(204),
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
  final dynamic media;
  final VoidCallback onTap;

  const _MediaCardHorizontal({required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withAlpha(26),
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
                color: CupertinoColors.systemGroupedBackground,
                child: Image.network(
                  media.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        CupertinoIcons.photo,
                        color: CupertinoColors.systemGrey,
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
                      color: CupertinoColors.systemGrey,
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
