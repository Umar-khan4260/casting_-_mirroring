import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class DeviceCard extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback onTap;

  const DeviceCard({Key? key, required this.device, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isConnected = device['isConnected'] == true;

    IconData getIcon() {
      switch (device['type']) {
        case 'tv':
          return Icons.tv;
        case 'apple_tv':
          return Icons.apple;
        case 'speaker':
          return Icons.speaker;
        default:
          return Icons.devices;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        child: Padding(
          padding: AppSpacing.paddingAllMd,
          child: Row(
            children: [
              Container(
                padding: AppSpacing.paddingAllSm,
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.primary.withAlpha(26)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusSm,
                  ),
                ),
                child: Icon(
                  getIcon(),
                  color: isConnected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device['name'],
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected ? 'Connected' : 'Available',
                      style: AppTypography.bodySmall.copyWith(
                        color: isConnected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
