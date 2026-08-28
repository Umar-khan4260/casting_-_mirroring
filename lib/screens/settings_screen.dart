import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _settings = const AppSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _updateSettings(AppSettings Function(AppSettings) updater) async {
    final updated = updater(_settings);
    setState(() => _settings = updated);
    await updated.save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.sm),
          _buildGeneralSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildCastingSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildScreenMirroringSection(),
          const SizedBox(height: AppSpacing.lg),
          _buildAboutSection(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    return _buildSection(
      'General',
      [
        _buildNavigationRow(
          icon: CupertinoIcons.paintbrush,
          iconColor: AppColors.primary,
          title: 'App Appearance',
          trailingText: _appearanceLabel(_settings.appearance),
          onTap: () => _showAppearanceSheet(),
        ),
        _buildDivider(),
        _buildSwitchRow(
          icon: CupertinoIcons.link,
          iconColor: AppColors.success,
          title: 'Auto-Connect',
          subtitle: 'Automatically connect to known devices',
          value: _settings.autoConnect,
          onChanged: (v) => _updateSettings((s) => s.copyWith(autoConnect: v)),
        ),
        _buildDivider(),
        _buildSwitchRow(
          icon: CupertinoIcons.hand_raised,
          iconColor: AppColors.secondary,
          title: 'Haptic Feedback',
          subtitle: 'Vibrate on interactions',
          value: _settings.hapticFeedback,
          onChanged: (v) => _updateSettings((s) => s.copyWith(hapticFeedback: v)),
        ),
      ],
    );
  }

  Widget _buildCastingSection() {
    return _buildSection(
      'Casting',
      [
        _buildNavigationRow(
          icon: CupertinoIcons.speaker_2,
          iconColor: AppColors.primary,
          title: 'Default Receiver',
          trailingText: _settings.defaultReceiver.isEmpty
              ? 'None'
              : _settings.defaultReceiver,
          onTap: () {},
        ),
        _buildDivider(),
        _buildSwitchRow(
          icon: CupertinoIcons.play,
          iconColor: AppColors.success,
          title: 'Auto-Play',
          subtitle: 'Start playing on connect',
          value: _settings.autoPlay,
          onChanged: (v) => _updateSettings((s) => s.copyWith(autoPlay: v)),
        ),
        _buildDivider(),
        _buildNavigationRow(
          icon: CupertinoIcons.forward,
          iconColor: AppColors.secondary,
          title: 'Playback Behavior',
          trailingText: _playbackLabel(_settings.playbackBehavior),
          onTap: () => _showPlaybackSheet(),
        ),
      ],
    );
  }

  Widget _buildScreenMirroringSection() {
    return _buildSection(
      'Screen Mirroring',
      [
        _buildNavigationRow(
          icon: CupertinoIcons.rectangle_expand_vertical,
          iconColor: AppColors.primary,
          title: 'Preferred Receiver',
          trailingText: _settings.preferredReceiver.isEmpty
              ? 'None'
              : _settings.preferredReceiver,
          onTap: () {},
        ),
        _buildDivider(),
        _buildNavigationRow(
          icon: CupertinoIcons.photo,
          iconColor: AppColors.secondary,
          title: 'Mirror Quality',
          trailingText: _mirrorQualityLabel(_settings.mirrorQuality),
          onTap: () => _showMirrorQualitySheet(),
        ),
        _buildDivider(),
        _buildNavigationRow(
          icon: CupertinoIcons.speedometer,
          iconColor: AppColors.success,
          title: 'Frame Rate',
          trailingText: _frameRateLabel(_settings.frameRate),
          onTap: () => _showFrameRateSheet(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      'About',
      [
        _buildNavigationRow(
          icon: CupertinoIcons.info,
          iconColor: AppColors.textSecondary,
          title: 'App Version',
          trailingText: '1.0.0',
          showChevron: false,
          onTap: () {},
        ),
        _buildDivider(),
        _buildNavigationRow(
          icon: CupertinoIcons.lock,
          iconColor: AppColors.primary,
          title: 'Privacy',
          onTap: () {},
        ),
        _buildDivider(),
        _buildNavigationRow(
          icon: CupertinoIcons.doc_text,
          iconColor: AppColors.primary,
          title: 'Terms',
          onTap: () {},
        ),
        _buildDivider(),
        _buildNavigationRow(
          icon: CupertinoIcons.question_circle,
          iconColor: AppColors.primary,
          title: 'Help',
          onTap: () {},
        ),
      ],
    );
  }

  // --- Section wrapper ---

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
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
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  // --- Row types ---

  Widget _buildNavigationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailingText,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: Radius.zero,
        bottom: Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTypography.bodyLarge),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  trailingText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (showChevron)
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

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyLarge),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: AppTypography.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 58),
      child: Divider(height: 0.5, thickness: 0.5, color: AppColors.divider),
    );
  }

  // --- Sheets ---

  void _showAppearanceSheet() {
    _showCupertinoActionSheet(
      title: 'App Appearance',
      options: AppAppearance.values,
      labels: const ['System', 'Light', 'Dark'],
      selectedIndex: _settings.appearance.index,
      onTap: (index) {
        _updateSettings(
          (s) => s.copyWith(appearance: AppAppearance.values[index]),
        );
        Navigator.pop(context);
      },
    );
  }

  void _showPlaybackSheet() {
    _showCupertinoActionSheet(
      title: 'Playback Behavior',
      options: PlaybackBehavior.values,
      labels: const ['Continue Playing', 'Stop', 'Queue Next'],
      selectedIndex: _settings.playbackBehavior.index,
      onTap: (index) {
        _updateSettings(
          (s) => s.copyWith(playbackBehavior: PlaybackBehavior.values[index]),
        );
        Navigator.pop(context);
      },
    );
  }

  void _showMirrorQualitySheet() {
    _showCupertinoActionSheet(
      title: 'Mirror Quality',
      options: MirrorQuality.values,
      labels: const ['Auto', 'High', 'Medium', 'Low'],
      selectedIndex: _settings.mirrorQuality.index,
      onTap: (index) {
        _updateSettings(
          (s) => s.copyWith(mirrorQuality: MirrorQuality.values[index]),
        );
        Navigator.pop(context);
      },
    );
  }

  void _showFrameRateSheet() {
    _showCupertinoActionSheet(
      title: 'Frame Rate',
      options: FrameRate.values,
      labels: const ['Auto', '24 fps', '30 fps', '60 fps'],
      selectedIndex: _settings.frameRate.index,
      onTap: (index) {
        _updateSettings(
          (s) => s.copyWith(frameRate: FrameRate.values[index]),
        );
        Navigator.pop(context);
      },
    );
  }

  void _showCupertinoActionSheet<T>({
    required String title,
    required List<T> options,
    required List<String> labels,
    required int selectedIndex,
    required void Function(int) onTap,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return CupertinoActionSheetAction(
            onPressed: () => onTap(index),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(labels[index]),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark, size: 16),
                ],
              ],
            ),
          );
        }),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // --- Labels ---

  static String _appearanceLabel(AppAppearance v) {
    switch (v) {
      case AppAppearance.system:
        return 'System';
      case AppAppearance.light:
        return 'Light';
      case AppAppearance.dark:
        return 'Dark';
    }
  }

  static String _playbackLabel(PlaybackBehavior v) {
    switch (v) {
      case PlaybackBehavior.continuePlaying:
        return 'Continue';
      case PlaybackBehavior.stop:
        return 'Stop';
      case PlaybackBehavior.queueNext:
        return 'Queue Next';
    }
  }

  static String _mirrorQualityLabel(MirrorQuality v) {
    switch (v) {
      case MirrorQuality.auto:
        return 'Auto';
      case MirrorQuality.high:
        return 'High';
      case MirrorQuality.medium:
        return 'Medium';
      case MirrorQuality.low:
        return 'Low';
    }
  }

  static String _frameRateLabel(FrameRate v) {
    switch (v) {
      case FrameRate.auto:
        return 'Auto';
      case FrameRate.fps24:
        return '24 fps';
      case FrameRate.fps30:
        return '30 fps';
      case FrameRate.fps60:
        return '60 fps';
    }
  }
}
