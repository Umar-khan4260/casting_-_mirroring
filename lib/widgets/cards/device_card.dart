import 'package:flutter/material.dart';
import '../../models/cast_device.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class DeviceCard extends StatelessWidget {
  final CastDevice device;
  final VoidCallback? onTap;

  const DeviceCard({Key? key, required this.device, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled =
        device.connectionState == DeviceConnectionState.error ||
        device.connectionState == DeviceConnectionState.connecting;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        child: Padding(
          padding: AppSpacing.paddingAllMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (device.supportsMediaCasting ||
                  device.supportsScreenMirroring) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                _buildCapabilities(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildIcon(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: device.connectionState == DeviceConnectionState.error
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildIcon() {
    final color = _iconColor();

    return Container(
      padding: AppSpacing.paddingAllSm,
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      ),
      child: device.connectionState == DeviceConnectionState.connecting
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Icon(_deviceIcon(), color: color, size: 24),
    );
  }

  Widget _buildStatusBadge() {
    if (device.connectionState == DeviceConnectionState.connected) {
      return const Icon(Icons.check_circle, color: AppColors.primary, size: 20);
    }
    if (device.connectionState == DeviceConnectionState.connecting) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9500)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCapabilities() {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Column(
        children: [
          _buildCapabilityRow(
            label: 'Media Casting',
            supported: device.supportsMediaCasting,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildCapabilityRow(
            label: 'Screen Mirroring',
            supported: device.supportsScreenMirroring,
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow({required String label, required bool supported}) {
    return Row(
      children: [
        Icon(
          supported ? Icons.check_circle : Icons.remove_circle_outline,
          size: 16,
          color: supported ? AppColors.success : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            color: supported ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          supported ? '\u2713' : '\u2014',
          style: AppTypography.bodyMedium.copyWith(
            color: supported ? AppColors.success : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _iconColor() {
    switch (device.connectionState) {
      case DeviceConnectionState.connected:
        return AppColors.primary;
      case DeviceConnectionState.disconnected:
        return AppColors.success;
      case DeviceConnectionState.connecting:
      case DeviceConnectionState.disconnecting:
        return const Color(0xFFFF9500);
      case DeviceConnectionState.error:
        return AppColors.textSecondary;
    }
  }

  IconData _deviceIcon() {
    switch (device.type) {
      case DeviceType.googleCast:
        return Icons.cast;
      case DeviceType.appleAirPlay:
        return Icons.apple;
      default:
        return Icons.devices;
    }
  }
}
