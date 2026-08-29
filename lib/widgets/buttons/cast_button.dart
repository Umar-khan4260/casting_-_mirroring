import 'package:flutter/material.dart';
import '../../models/cast_device.dart';
import '../../theme/app_colors.dart';

class CastButton extends StatelessWidget {
  final DeviceConnectionState connectionState;
  final VoidCallback onPressed;

  const CastButton({
    super.key,
    this.connectionState = DeviceConnectionState.disconnected,
    required this.onPressed,
  });

  const CastButton.connected({
    super.key,
    required this.onPressed,
  }) : connectionState = DeviceConnectionState.connected;

  const CastButton.disconnected({
    super.key,
    required this.onPressed,
  }) : connectionState = DeviceConnectionState.disconnected;

  bool get isConnected => connectionState == DeviceConnectionState.connected;
  bool get isConnecting =>
      connectionState == DeviceConnectionState.connecting;
  bool get isDisconnecting =>
      connectionState == DeviceConnectionState.disconnecting;
  bool get hasError => connectionState == DeviceConnectionState.error;

  @override
  Widget build(BuildContext context) {
    if (isConnecting || isDisconnecting) {
      return IconButton(
        icon: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        onPressed: null,
      );
    }

    if (hasError) {
      return IconButton(
        icon: Icon(
          Icons.cast,
          color: AppColors.error,
        ),
        onPressed: onPressed,
      );
    }

    return IconButton(
      icon: Icon(
        isConnected ? Icons.cast_connected : Icons.cast,
        color: isConnected ? AppColors.primary : AppColors.textPrimary,
      ),
      onPressed: onPressed,
    );
  }
}
