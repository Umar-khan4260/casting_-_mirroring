import 'package:flutter/cupertino.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/cards/action_card.dart';
import '../widgets/cards/connected_device_card.dart';
import '../widgets/cards/media_card.dart';
import '../mock/mock_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For demonstration, we'll use the first device as connected
    final connectedDevice = MockData.devices.firstWhere(
      (d) => d['isConnected'] == true,
      orElse: () => MockData.devices[0],
    );

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Casting App')),
      child: SafeArea(
        child: ListView(
          padding: AppSpacing.paddingAllLg,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'Currently connected TV',
              style: AppTypography.bodyMedium.copyWith(
                color: CupertinoColors.systemGrey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConnectedDeviceCard(
              device: connectedDevice,
              onSelectDevice: () {
                // Navigate to devices tab or show bottom sheet
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('What do you want to do?', style: AppTypography.heading3),
            const SizedBox(height: AppSpacing.md),
            ActionCard(
              title: 'Cast Media',
              subtitle: 'Videos, photos and music',
              icon: CupertinoIcons.play_rectangle,
              iconColor: CupertinoColors.activeBlue,
              onTap: () {},
            ),
            ActionCard(
              title: 'Mirror Screen',
              subtitle: 'Mirror your iPhone',
              icon: CupertinoIcons.device_phone_portrait,
              iconColor: CupertinoColors.systemPurple,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Recently Cast', style: AppTypography.heading3),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.mediaItems.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: AppSpacing.md),
                    child: MediaCard(
                      media: MockData.mediaItems[index],
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: AppSpacing.xxl,
            ), // Bottom padding for mini player
          ],
        ),
      ),
    );
  }
}
