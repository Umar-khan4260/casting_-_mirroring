import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/cast_device.dart';
import '../../providers/device_discovery_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class DevicePickerSheet extends StatefulWidget {
  final Function(CastDevice)? onDeviceSelected;
  final bool showMirrorOption;

  const DevicePickerSheet({
    super.key,
    this.onDeviceSelected,
    this.showMirrorOption = false,
  });

  static Future<CastDevice?> show(
    BuildContext context, {
    Function(CastDevice)? onDeviceSelected,
    bool showMirrorOption = false,
  }) {
    return showModalBottomSheet<CastDevice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DevicePickerSheet(
        onDeviceSelected: onDeviceSelected,
        showMirrorOption: showMirrorOption,
      ),
    );
  }

  @override
  State<DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends State<DevicePickerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  CastDevice? _selectedDevice;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _connectToDevice(CastDevice device) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _selectedDevice = device;
    });

    try {
      final discoveryProvider = DeviceDiscoveryProvider.of(context);
      await discoveryProvider.connectTo(device);

      if (mounted) {
        widget.onDeviceSelected?.call(device);
        Navigator.of(context).pop(device);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _selectedDevice = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.borderRadiusLg),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.sm),
                _buildDragHandle(),
                const SizedBox(height: AppSpacing.lg),
                _buildHeader(),
                const SizedBox(height: AppSpacing.lg),
                _buildDeviceList(),
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

  Widget _buildHeader() {
    return Padding(
      padding: AppSpacing.paddingHorizontalMd,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Select Device', style: AppTypography.heading3),
          IconButton(
            icon: const Icon(CupertinoIcons.xmark_circle_fill),
            color: CupertinoColors.systemGrey3,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Builder(
      builder: (context) {
        final discoveryProvider = DeviceDiscoveryProvider.of(context);
        final devices = discoveryProvider.devices;
        final discoveryState = discoveryProvider.state;

        if (devices.isEmpty) {
          return _buildEmptyState(discoveryState);
        }

        return Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: AppSpacing.paddingHorizontalMd,
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return _DeviceTile(
                device: device,
                isSelected: _selectedDevice?.id == device.id,
                isConnecting:
                    _isConnecting && _selectedDevice?.id == device.id,
                onTap: () => _connectToDevice(device),
                showMirrorOption: widget.showMirrorOption,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(DiscoveryState state) {
    String title;
    String message;
    IconData icon;

    switch (state) {
      case DiscoveryState.loading:
        title = 'Searching for devices...';
        message = 'Make sure your devices are on the same network';
        icon = CupertinoIcons.search;
        break;
      case DiscoveryState.error:
        title = 'Discovery failed';
        message = 'Unable to find devices. Please try again.';
        icon = CupertinoIcons.exclamationmark_circle;
        break;
      case DiscoveryState.idle:
      case DiscoveryState.loaded:
        title = 'No devices found';
        message = 'Make sure your casting devices are on the same network';
        icon = CupertinoIcons.device_desktop;
        break;
    }

    return Padding(
      padding: AppSpacing.paddingAllLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (state == DiscoveryState.loading) ...[
            const SizedBox(height: AppSpacing.lg),
            const CupertinoActivityIndicator(),
          ],
          if (state == DiscoveryState.error) ...[
            const SizedBox(height: AppSpacing.lg),
            CupertinoButton(
              child: const Text('Retry'),
              onPressed: () {
                DeviceDiscoveryProvider.of(context).discoverDevices();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final CastDevice device;
  final bool isSelected;
  final bool isConnecting;
  final VoidCallback onTap;
  final bool showMirrorOption;

  const _DeviceTile({
    required this.device,
    required this.isSelected,
    required this.isConnecting,
    required this.onTap,
    required this.showMirrorOption,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected =
        device.connectionState == DeviceConnectionState.connected;
    final isAvailable =
        device.connectionState == DeviceConnectionState.disconnected;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withAlpha(26)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: AppSpacing.paddingAllMd,
        leading: Container(
          padding: AppSpacing.paddingAllSm,
          decoration: BoxDecoration(
            color: isConnected
                ? AppColors.primary.withAlpha(26)
                : AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getDeviceIcon(device.type),
            color: isConnected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
        ),
        title: Text(
          device.name,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _getDeviceStatus(device),
          style: AppTypography.bodySmall.copyWith(
            color: _getStatusColor(device),
          ),
        ),
        trailing: isConnecting
            ? const CupertinoActivityIndicator(radius: 12)
            : isConnected
                ? const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.primary,
                    size: 24,
                  )
                : isAvailable
                    ? const Icon(
                        CupertinoIcons.chevron_right,
                        color: AppColors.textSecondary,
                        size: 18,
                      )
                    : null,
        onTap: isAvailable || isConnected ? onTap : null,
      ),
    );
  }

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.googleCast:
        return Icons.cast;
      case DeviceType.appleAirPlay:
        return Icons.airplay;
      case DeviceType.unknown:
        return Icons.devices;
    }
  }

  String _getDeviceStatus(CastDevice device) {
    switch (device.connectionState) {
      case DeviceConnectionState.connected:
        return 'Connected';
      case DeviceConnectionState.connecting:
        return 'Connecting...';
      case DeviceConnectionState.disconnected:
        return 'Available';
      case DeviceConnectionState.disconnecting:
        return 'Disconnecting...';
      case DeviceConnectionState.error:
        return 'Connection failed';
    }
  }

  Color _getStatusColor(CastDevice device) {
    switch (device.connectionState) {
      case DeviceConnectionState.connected:
        return AppColors.primary;
      case DeviceConnectionState.connecting:
      case DeviceConnectionState.disconnecting:
        return AppColors.textSecondary;
      case DeviceConnectionState.disconnected:
        return AppColors.textSecondary;
      case DeviceConnectionState.error:
        return AppColors.error;
    }
  }
}
