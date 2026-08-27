import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class CastButton extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onPressed;

  const CastButton({
    Key? key,
    this.isConnected = false,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isConnected ? Icons.cast_connected : Icons.cast,
        color: isConnected ? AppColors.primary : AppColors.textPrimary,
      ),
      onPressed: onPressed,
    );
  }
}
