import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/media_item.dart';
import '../../models/media_player_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class MiniPlayer extends StatelessWidget {
  final MediaPlayerState playerState;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onClose;

  const MiniPlayer({
    super.key,
    required this.playerState,
    required this.onTap,
    required this.onPlayPause,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final media = playerState.media;
    if (media == null) return const SizedBox.shrink();

    final status = playerState.status;
    final isLoading = status == PlayerStatus.loading;

    return GestureDetector(
      onTap: onTap,
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy < -100) {
          onTap();
        }
      },
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playerState.duration.inSeconds > 0)
              LinearProgressIndicator(
                value: playerState.progress,
                backgroundColor: AppColors.divider.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLoading ? AppColors.textSecondary : AppColors.primary,
                ),
                minHeight: 2,
              ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    color: AppColors.background,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          media.thumbnailUrl,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              media.type == MediaType.music
                                  ? CupertinoIcons.music_note
                                  : CupertinoIcons.play_rectangle,
                              color: AppColors.textSecondary,
                            );
                          },
                        ),
                        if (isLoading)
                          Container(
                            width: 56,
                            height: 56,
                            color: Colors.black.withAlpha(51),
                            child: const CupertinoActivityIndicator(
                              radius: 10,
                              color: CupertinoColors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.title,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getConnectionStatusColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Casting to ${playerState.connectedDevice?.name ?? "Device"}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: _getConnectionStatusColor(),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : onPlayPause,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: isLoading
                          ? const CupertinoActivityIndicator(radius: 10)
                          : Icon(
                              playerState.isPlaying
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_fill,
                              color: AppColors.primary,
                              size: 26,
                            ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCloseConfirmation(context),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConnectionStatusColor() {
    switch (playerState.status) {
      case PlayerStatus.idle:
        return AppColors.textSecondary;
      case PlayerStatus.loading:
        return CupertinoColors.systemYellow;
      case PlayerStatus.casting:
        return AppColors.primary;
      case PlayerStatus.paused:
        return AppColors.primary;
      case PlayerStatus.error:
        return AppColors.error;
    }
  }

  void _showCloseConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Stop Casting?'),
        content: const Text('This will stop the current playback.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Stop'),
            onPressed: () {
              Navigator.of(context).pop();
              onClose();
            },
          ),
        ],
      ),
    );
  }
}
