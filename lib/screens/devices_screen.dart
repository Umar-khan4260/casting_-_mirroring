import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/device_card.dart';
import '../mock/mock_data.dart';
import '../widgets/buttons/primary_button.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Devices')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.paddingAllMd,
              itemCount: MockData.devices.length,
              itemBuilder: (context, index) {
                return DeviceCard(
                  device: MockData.devices[index],
                  onTap: () {},
                );
              },
            ),
          ),
          Padding(
            padding: AppSpacing.paddingAllMd,
            child: PrimaryButton(
              text: 'Scan for Devices',
              icon: Icons.search,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
