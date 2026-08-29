import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../mock/mock_data.dart';
import '../widgets/buttons/cast_button.dart';
import '../models/cast_device.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Library'),
        actions: [
          CastButton(
            connectionState: DeviceConnectionState.connected,
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: AppSpacing.paddingAllMd,
        itemCount: MockData.mediaItems.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(MockData.mediaItems[index]['title']),
            subtitle: Text(MockData.mediaItems[index]['subtitle']),
            onTap: () {},
          );
        },
      ),
    );
  }
}
