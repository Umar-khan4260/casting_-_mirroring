import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/main_shell.dart';
import 'providers/device_discovery_provider.dart';

void main() {
  runApp(const CastingApp());
}

class CastingApp extends StatelessWidget {
  const CastingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DeviceDiscoveryProvider(
      child: CupertinoApp(
        title: 'Cast & Mirror',
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(
          primaryColor: CupertinoColors.activeBlue,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
          barBackgroundColor: CupertinoColors.systemBackground,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        home: const MainShell(),
      ),
    );
  }
}
