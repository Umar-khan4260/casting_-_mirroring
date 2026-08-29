import 'package:flutter/cupertino.dart';
import '../../models/cast_device.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';

class ConnectedDeviceCard extends StatelessWidget {
  final CastDevice? device;
  final VoidCallback onSelectDevice;

  const ConnectedDeviceCard({
    super.key,
    this.device,
    required this.onSelectDevice,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected =
        device?.connectionState == DeviceConnectionState.connected;
    final isConnecting =
        device?.connectionState == DeviceConnectionState.connecting;

    return GestureDetector(
      onTap: onSelectDevice,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.paddingAllLg,
        decoration: BoxDecoration(
          color: isConnected
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: isConnected
                  ? CupertinoColors.activeBlue.withAlpha(76)
                  : CupertinoColors.systemGrey.withAlpha(26),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isConnecting)
              const CupertinoActivityIndicator(
                color: CupertinoColors.activeBlue,
                radius: 24,
              )
            else
              Icon(
                isConnected ? CupertinoIcons.tv : CupertinoIcons.tv_circle,
                size: 48,
                color: isConnected
                    ? CupertinoColors.white
                    : CupertinoColors.systemGrey,
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isConnected
                  ? (device?.name ?? 'Connected')
                  : 'Select a device',
              style: AppTypography.heading3.copyWith(
                color: isConnected
                    ? CupertinoColors.white
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isConnected
                  ? 'Connected'
                  : isConnecting
                      ? 'Connecting...'
                      : 'Tap to connect',
              style: AppTypography.bodyMedium.copyWith(
                color: isConnected
                    ? CupertinoColors.white.withAlpha(204)
                    : CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
