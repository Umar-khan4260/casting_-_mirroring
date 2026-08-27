import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/media_card.dart';
import '../mock/mock_data.dart';
import '../widgets/buttons/cast_button.dart';

class MediaScreen extends StatelessWidget {
  const MediaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Library'),
        actions: [CastButton(isConnected: true, onPressed: () {})],
      ),
      body: ListView.builder(
        padding: AppSpacing.paddingAllMd,
        itemCount: MockData.mediaItems.length,
        itemBuilder: (context, index) {
          return MediaCard(media: MockData.mediaItems[index], onTap: () {});
        },
      ),
    );
  }
}
