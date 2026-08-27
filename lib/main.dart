import 'package:flutter/cupertino.dart';

import 'screens/main_shell.dart';

void main() {
  runApp(const CastingApp());
}

class CastingApp extends StatelessWidget {
  const CastingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Cast & Mirror',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        barBackgroundColor: CupertinoColors.systemBackground,
      ),
      home: MainShell(),
    );
  }
}
