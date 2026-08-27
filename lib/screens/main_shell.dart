import 'package:flutter/cupertino.dart';
import 'home_screen.dart';
import 'media_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';
import '../mock/mock_data.dart';
import '../widgets/player/mini_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _showMiniPlayer = true;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MediaScreen(),
    const DevicesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                activeIcon: Icon(CupertinoIcons.house_fill),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.play_circle),
                activeIcon: Icon(CupertinoIcons.play_circle_fill),
                label: 'Media',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.device_desktop),
                label: 'Devices',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                activeIcon: Icon(CupertinoIcons.settings_solid),
                label: 'Settings',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(
              builder: (context) {
                return _screens[index];
              },
            );
          },
        ),
        if (_showMiniPlayer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 50, // Above the tab bar
            child: MiniPlayer(
              media: MockData.mediaItems[0],
              onTap: () {},
              onPlayPause: () {},
              onClose: () {
                setState(() {
                  _showMiniPlayer = false;
                });
              },
            ),
          ),
      ],
    );
  }
}
