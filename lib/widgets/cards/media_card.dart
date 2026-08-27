import 'package:flutter/cupertino.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class MediaCard extends StatelessWidget {
  final Map<String, dynamic> media;
  final VoidCallback onTap;

  const MediaCard({super.key, required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                  media['imageUrl'],
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
                    media['title'],
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    media['subtitle'],
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
