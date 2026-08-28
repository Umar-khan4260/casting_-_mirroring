import 'package:flutter/material.dart';
import '../models/cast_device.dart';
import '../providers/device_discovery_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../widgets/cards/device_card.dart';
import '../widgets/states/loading_state.dart';
import '../widgets/states/error_state.dart';
import '../widgets/states/empty_state.dart';
import '../widgets/layout/section_header.dart';
import '../widgets/sheets/device_action_sheet.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Device')),
      body: Builder(
        builder: (context) {
          final provider = DeviceDiscoveryProvider.of(context);

          switch (provider.state) {
            case DiscoveryState.idle:
            case DiscoveryState.loading:
              return const LoadingState();

            case DiscoveryState.error:
              return ErrorState(
                message: provider.errorMessage ?? 'Something went wrong.',
                onRetry: () => provider.discoverDevices(),
              );

            case DiscoveryState.loaded:
              if (provider.devices.isEmpty) {
                return EmptyState(
                  title: 'No devices found',
                  message:
                      'Make sure your casting device is on the same Wi-Fi network.',
                  icon: Icons.devices_other,
                );
              }
              return _buildDeviceList(provider);
          }
        },
      ),
    );
  }

  Widget _buildDeviceList(DeviceDiscoveryProviderState provider) {
    final connected = provider.connectedDevices;
    final available = provider.availableDevices;
    final unavailable = provider.unavailableDevices;

    return RefreshIndicator(
      onRefresh: () => provider.discoverDevices(),
      color: AppColors.primary,
      child: ListView(
        padding: AppSpacing.paddingAllMd,
        children: [
          if (connected.isNotEmpty || available.isNotEmpty) ...[
            const SectionHeader(title: 'Your devices'),
            ...connected.map((d) => _buildDeviceCard(d, provider)),
            ...available.map((d) => _buildDeviceCard(d, provider)),
          ],
          if (unavailable.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const SectionHeader(title: 'Other devices'),
            ...unavailable.map((d) => _buildDeviceCard(d, provider)),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    CastDevice device,
    DeviceDiscoveryProviderState provider,
  ) {
    return DeviceCard(
      device: device,
      onTap: () {
        if (device.isConnected) {
          DeviceActionSheet.show(
            context,
            device: device,
            onCastMedia: () {},
            onMirrorScreen: () {},
            onDisconnect: () => provider.disconnect(device),
          );
        } else if (device.isAvailable) {
          provider.connectTo(device);
        }
      },
    );
  }
}
