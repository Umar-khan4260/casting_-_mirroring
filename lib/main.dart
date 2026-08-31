import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

import 'screens/main_shell.dart';
import 'providers/device_discovery_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
    try {
      const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
      GoogleCastOptions? options;
      if (Platform.isIOS) {
        options = IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
          stopCastingOnAppTerminated: true,
        );
      } else if (Platform.isAndroid) {
        options = GoogleCastOptionsAndroid(
          appId: appId,
          stopCastingOnAppTerminated: true,
        );
      }

      if (options != null) {
        GoogleCastContext.instance.setSharedInstanceWithOptions(options);
      }
    } catch (e) {
      debugPrint('Google Cast init skipped: $e');
    }
  }

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
          brightness: Brightness.light,
          primaryColor: CupertinoColors.activeBlue,
          scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
          barBackgroundColor: CupertinoColors.systemBackground,
          textTheme: CupertinoTextThemeData(
            primaryColor: CupertinoColors.activeBlue,
          ),
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
