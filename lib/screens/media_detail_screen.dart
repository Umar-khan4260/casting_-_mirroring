import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../providers/app_casting_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'cast_player_screen.dart';

class MediaDetailScreen extends StatelessWidget {
  final MediaItem media;

  const MediaDetailScreen({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _appBarTitle,
          style: AppTypography.heading3.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              media.isFavorite
                  ? CupertinoIcons.heart_fill
                  : CupertinoIcons.heart,
              color: media.isFavorite ? AppColors.error : null,
              size: 22,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.share, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            Padding(
              padding: AppSpacing.paddingAllMd,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildInfoSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildActionSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _appBarTitle {
    switch (media.type) {
      case MediaType.video:
        return 'Video';
      case MediaType.music:
        return 'Song';
      case MediaType.photo:
        return 'Photo';
    }
  }

  Widget _buildThumbnail() {
    return Container(
      width: double.infinity,
      color: CupertinoColors.black,
      child: AspectRatio(
        aspectRatio: media.type == MediaType.music ? 1 : 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              media.thumbnailUrl,
              fit: media.type == MediaType.music ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    _typeIcon,
                    color: CupertinoColors.systemGrey,
                    size: 60,
                  ),
                );
              },
            ),
            if (media.type == MediaType.video)
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.play_fill,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
            if (media.duration.inSeconds > 0)
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.7),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadiusSm),
                  ),
                  child: Text(
                    media.formattedDuration,
                    style: AppTypography.bodySmall.copyWith(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(media.title, style: AppTypography.heading2),
        const SizedBox(height: AppSpacing.xs),
        if (media.artist != null)
          Text(
            media.artist!,
            style: AppTypography.bodyLarge.copyWith(color: AppColors.primary),
          )
        else
          Text(media.subtitle, style: AppTypography.bodyMedium),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
      ),
      child: Column(
        children: [
          _buildInfoRow(CupertinoIcons.tag, 'Type', _typeLabel),
          if (media.album != null)
            _buildInfoRow(CupertinoIcons.collections, 'Album', media.album!),
          if (media.artist != null)
            _buildInfoRow(CupertinoIcons.person, 'Artist', media.artist!),
          if (media.duration.inSeconds > 0)
            _buildInfoRow(
              CupertinoIcons.clock,
              'Duration',
              media.formattedDuration,
            ),
          _buildInfoRow(
            CupertinoIcons.calendar,
            'Added',
            _formatDateAdded(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (media.type == MediaType.video || media.type == MediaType.music)
          _buildActionButton(
            context: context,
            icon: CupertinoIcons.tv,
            label: 'Cast to Device',
            isPrimary: true,
            onTap: () {
              AppCastingController().loadAndCast(media);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => CastPlayerScreen(media: media),
                ),
              );
            },
          ),
        const SizedBox(height: AppSpacing.sm),
        _buildActionButton(
          context: context,
          icon: CupertinoIcons.share,
          label: 'Share',
          isPrimary: false,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          border: isPrimary
              ? null
              : Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isPrimary ? CupertinoColors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color:
                    isPrimary ? CupertinoColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData get _typeIcon {
    switch (media.type) {
      case MediaType.video:
        return CupertinoIcons.film;
      case MediaType.music:
        return CupertinoIcons.music_note;
      case MediaType.photo:
        return CupertinoIcons.photo;
    }
  }

  String get _typeLabel {
    switch (media.type) {
      case MediaType.video:
        return 'Video';
      case MediaType.music:
        return 'Music';
      case MediaType.photo:
        return 'Photo';
    }
  }

  String _formatDateAdded() {
    final diff = DateTime.now().difference(media.dateAdded);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
