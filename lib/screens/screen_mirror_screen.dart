import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../casting_core/interfaces/screen_mirroring_interface.dart';
import '../screen_mirroring/screen_mirror_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// CupertinoIcons.airplay is not available in this Flutter version.
// Using a Material icon as fallback for AirPlay indicator.
const IconData _airPlayIcon = Icons.airplay;

/// Screen for managing AirPlay screen mirroring.
///
/// This screen provides:
/// - AirPlay route picker (for media routing to Apple TV / AirPlay receivers)
/// - Detection of active system-level screen mirroring
/// - User guidance for enabling full-device mirroring via Control Center
///
/// ## iOS Platform Limitation
///
/// This screen CANNOT programmatically start full-device screen mirroring.
/// iOS requires the user to manually go to Control Center → Screen Mirroring.
/// The UI clearly documents this limitation and provides step-by-step guidance.
class ScreenMirrorScreen extends StatefulWidget {
  const ScreenMirrorScreen({super.key});

  @override
  State<ScreenMirrorScreen> createState() => _ScreenMirrorScreenState();
}

class _ScreenMirrorScreenState extends State<ScreenMirrorScreen> {
  final ScreenMirrorController _controller = ScreenMirrorController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Screen Mirroring',
          style: AppTypography.heading3.copyWith(fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return SingleChildScrollView(
                  padding: AppSpacing.paddingAllMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildAirPlaySection(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildLimitationCard(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMirroringGuide(),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusCard() {
    final state = _controller.state;
    final isConnected = _controller.isConnected;

    Color cardColor;
    IconData icon;
    String title;
    String subtitle;

    switch (state) {
      case MirroringState.idle:
        cardColor = AppColors.background;
        icon = CupertinoIcons.rectangle_expand_vertical;
        title = 'No Mirroring Active';
        subtitle = 'Connect to an AirPlay device to start';
        break;
      case MirroringState.airPlayAvailable:
        cardColor = AppColors.primary.withAlpha(26);
        icon = _airPlayIcon;
        title = 'AirPlay Available';
        subtitle = 'Tap below to select a receiver';
        break;
      case MirroringState.airPlayConnected:
        cardColor = AppColors.primary;
        icon = _airPlayIcon;
        title = 'AirPlay Connected';
        subtitle = _controller.connectedRouteName ?? 'Connected';
        break;
      case MirroringState.systemMirroringActive:
        cardColor = AppColors.success;
        icon = CupertinoIcons.rectangle_expand_vertical;
        title = 'Screen Mirroring Active';
        subtitle = _controller.connectedRouteName ?? 'Mirroring to device';
        break;
      case MirroringState.error:
        cardColor = AppColors.error;
        icon = CupertinoIcons.exclamationmark_circle;
        title = 'Connection Error';
        subtitle = _controller.errorMessage ?? 'Unknown error';
        break;
    }

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAllLg,
      decoration: BoxDecoration(
        color: isConnected ? cardColor : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        boxShadow: isConnected
            ? [
                BoxShadow(
                  color: cardColor.withAlpha(76),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
        border: isConnected
            ? null
            : Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: isConnected
                ? CupertinoColors.white
                : AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.heading3.copyWith(
              color: isConnected ? CupertinoColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: isConnected
                  ? CupertinoColors.white.withAlpha(204)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirPlaySection() {
    return _buildSection(
      'AirPlay Media Routing',
      [
        _buildActionTile(
          icon: _airPlayIcon,
          iconColor: AppColors.primary,
          title: 'Select AirPlay Device',
          subtitle: 'Route media to Apple TV or AirPlay speakers',
          onTap: () async {
            final success = await _controller.showRoutePicker();
            if (mounted && !success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not show AirPlay picker'),
                ),
              );
            }
          },
        ),
        if (_controller.isConnected) ...[
          _buildDivider(),
          _buildActionTile(
            icon: CupertinoIcons.stop_circle,
            iconColor: AppColors.error,
            title: 'Disconnect',
            subtitle: 'Stop routing to ${_controller.connectedRouteName ?? "device"}',
            onTap: () async {
              await _controller.stopMirroring();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLimitationCard() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingAllMd,
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withAlpha(26),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        border: Border.all(
          color: CupertinoColors.systemOrange.withAlpha(76),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 20,
                color: CupertinoColors.systemOrange,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Platform Limitation',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.systemOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'iOS does not allow third-party apps to programmatically start '
            'full-device screen mirroring. To mirror your entire iPhone screen '
            '(including home screen, other apps, and system UI) to an AirPlay '
            'receiver, you must use Control Center.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMirroringGuide() {
    return _buildSection(
      'How to Mirror Your Screen',
      [
        Padding(
          padding: AppSpacing.paddingAllMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGuideStep(1, 'Swipe down from the top-right corner'),
              _buildGuideStep(2, 'Tap the Screen Mirroring button'),
              _buildGuideStep(3, 'Select your AirPlay receiver'),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingAllMd,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'This mirrors the ENTIRE iPhone screen, not just media content.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: AppSpacing.paddingAllMd,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(26),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 68),
      child: Divider(height: 0.5, thickness: 0.5, color: AppColors.divider),
    );
  }
}
