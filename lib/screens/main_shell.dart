import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'media_library_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';
import 'cast_player_screen.dart';
import '../models/media_player_state.dart';
import '../providers/app_casting_controller.dart';
import '../widgets/player/mini_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final AppCastingController _castingController = AppCastingController();

  final List<Widget> _screens = [
    const HomeScreen(),
    const MediaLibraryScreen(),
    const DevicesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _castingController.initialize();
    _castingController.addListener(_onCastingChanged);
  }

  @override
  void dispose() {
    _castingController.removeListener(_onCastingChanged);
    super.dispose();
  }

  void _onCastingChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _castingController.state;
    final showMiniPlayer = _castingController.isCasting;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
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
          if (showMiniPlayer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 50,
              child: MiniPlayer(
                playerState: state,
                onTap: () {
                  _openFullPlayer(state);
                },
                onPlayPause: () {
                  _castingController.playPause();
                },
                onClose: () {
                  _castingController.disconnect();
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openFullPlayer(MediaPlayerState state) {
    if (state.media == null) return;
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => CastPlayerScreen(media: state.media!),
      ),
    );
  }
}
