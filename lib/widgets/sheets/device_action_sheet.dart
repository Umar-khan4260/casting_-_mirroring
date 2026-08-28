import 'package:flutter/material.dart';
import '../../models/cast_device.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class DeviceActionSheet extends StatefulWidget {
  final CastDevice device;
  final VoidCallback? onCastMedia;
  final VoidCallback? onMirrorScreen;
  final VoidCallback? onDisconnect;

  const DeviceActionSheet({
    Key? key,
    required this.device,
    this.onCastMedia,
    this.onMirrorScreen,
    this.onDisconnect,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required CastDevice device,
    VoidCallback? onCastMedia,
    VoidCallback? onMirrorScreen,
    VoidCallback? onDisconnect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DeviceActionSheet(
        device: device,
        onCastMedia: onCastMedia,
        onMirrorScreen: onMirrorScreen,
        onDisconnect: onDisconnect,
      ),
    );
  }

  @override
  State<DeviceActionSheet> createState() => _DeviceActionSheetState();
}

class _DeviceActionSheetState extends State<DeviceActionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final isConnected = device.isConnected;
    final showCast = device.mediaCasting;
    final showMirror = device.screenMirroring;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.borderRadiusLg),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                _buildDragHandle(),
                const SizedBox(height: AppSpacing.lg),
                _buildDeviceInfo(device, isConnected),
                const SizedBox(height: AppSpacing.lg),
                if (showCast || showMirror) ...[
                  Padding(
                    padding: AppSpacing.paddingHorizontalMd,
                    child: Column(
                      children: [
                        if (showCast)
                          _ActionCard(
                            icon: Icons.movie_creation_outlined,
                            title: 'Cast Media',
                            subtitle: 'Watch videos and listen to music on your TV',
                            delay: 100,
                            controller: _controller,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onCastMedia?.call();
                            },
                          ),
                        if (showCast && showMirror)
                          const SizedBox(height: AppSpacing.sm),
                        if (showMirror)
                          _ActionCard(
                            icon: Icons.phone_iphone,
                            title: 'Mirror Screen',
                            subtitle: 'Mirror your iPhone',
                            delay: 200,
                            controller: _controller,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onMirrorScreen?.call();
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (isConnected) ...[
                  Padding(
                    padding: AppSpacing.paddingHorizontalMd,
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDisconnect?.call();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: AppSpacing.paddingAllMd,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadiusMd,
                            ),
                          ),
                        ),
                        child: Text(
                          'Disconnect',
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDeviceInfo(CastDevice device, bool isConnected) {
    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Column(
        children: [
          Container(
            padding: AppSpacing.paddingAllMd,
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.primary.withAlpha(26)
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _deviceIcon(device.type),
              size: 32,
              color: isConnected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            device.name,
            style: AppTypography.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isConnected ? 'Connected' : (device.model ?? 'Available'),
            style: AppTypography.bodyMedium.copyWith(
              color: isConnected ? AppColors.primary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _deviceIcon(String type) {
    switch (type) {
      case 'tv':
        return Icons.tv;
      case 'chromecast':
        return Icons.cast;
      case 'apple_tv':
        return Icons.apple;
      case 'speaker':
        return Icons.speaker;
      default:
        return Icons.devices;
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int delay;
  final AnimationController controller;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.delay,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final elapsed = controller.lastElapsedDuration?.inMilliseconds ?? 0;
        final opacity = (elapsed - delay) / 200;
        final clampedOpacity = opacity.clamp(0.0, 1.0);

        return Opacity(
          opacity: clampedOpacity,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - clampedOpacity)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: AppSpacing.paddingAllMd,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          child: Row(
            children: [
              Container(
                padding: AppSpacing.paddingAllSm,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
