import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearance { system, light, dark }

enum PlaybackBehavior { continuePlaying, stop, queueNext }

enum MirrorQuality { auto, high, medium, low }

enum FrameRate { auto, fps24, fps30, fps60 }

class AppSettings {
  // General
  final AppAppearance appearance;
  final bool autoConnect;
  final bool hapticFeedback;

  // Casting
  final String defaultReceiver;
  final bool autoPlay;
  final PlaybackBehavior playbackBehavior;

  // Screen Mirroring
  final String preferredReceiver;
  final MirrorQuality mirrorQuality;
  final FrameRate frameRate;

  const AppSettings({
    this.appearance = AppAppearance.system,
    this.autoConnect = true,
    this.hapticFeedback = true,
    this.defaultReceiver = '',
    this.autoPlay = true,
    this.playbackBehavior = PlaybackBehavior.continuePlaying,
    this.preferredReceiver = '',
    this.mirrorQuality = MirrorQuality.auto,
    this.frameRate = FrameRate.auto,
  });

  AppSettings copyWith({
    AppAppearance? appearance,
    bool? autoConnect,
    bool? hapticFeedback,
    String? defaultReceiver,
    bool? autoPlay,
    PlaybackBehavior? playbackBehavior,
    String? preferredReceiver,
    MirrorQuality? mirrorQuality,
    FrameRate? frameRate,
  }) {
    return AppSettings(
      appearance: appearance ?? this.appearance,
      autoConnect: autoConnect ?? this.autoConnect,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      defaultReceiver: defaultReceiver ?? this.defaultReceiver,
      autoPlay: autoPlay ?? this.autoPlay,
      playbackBehavior: playbackBehavior ?? this.playbackBehavior,
      preferredReceiver: preferredReceiver ?? this.preferredReceiver,
      mirrorQuality: mirrorQuality ?? this.mirrorQuality,
      frameRate: frameRate ?? this.frameRate,
    );
  }

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      appearance: AppAppearance.values[prefs.getInt('appearance') ?? 0],
      autoConnect: prefs.getBool('autoConnect') ?? true,
      hapticFeedback: prefs.getBool('hapticFeedback') ?? true,
      defaultReceiver: prefs.getString('defaultReceiver') ?? '',
      autoPlay: prefs.getBool('autoPlay') ?? true,
      playbackBehavior:
          PlaybackBehavior.values[prefs.getInt('playbackBehavior') ?? 0],
      preferredReceiver: prefs.getString('preferredReceiver') ?? '',
      mirrorQuality: MirrorQuality.values[prefs.getInt('mirrorQuality') ?? 0],
      frameRate: FrameRate.values[prefs.getInt('frameRate') ?? 0],
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appearance', appearance.index);
    await prefs.setBool('autoConnect', autoConnect);
    await prefs.setBool('hapticFeedback', hapticFeedback);
    await prefs.setString('defaultReceiver', defaultReceiver);
    await prefs.setBool('autoPlay', autoPlay);
    await prefs.setInt('playbackBehavior', playbackBehavior.index);
    await prefs.setString('preferredReceiver', preferredReceiver);
    await prefs.setInt('mirrorQuality', mirrorQuality.index);
    await prefs.setInt('frameRate', frameRate.index);
  }
}
