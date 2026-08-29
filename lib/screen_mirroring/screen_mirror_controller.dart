import 'dart:async';
import 'package:flutter/foundation.dart';
import '../casting_core/interfaces/screen_mirroring_interface.dart';
import 'air_play_channel.dart';
import '../utils/cast_logger.dart';

const _log = CastLogger('ScreenMirrorCtrl');

class ScreenMirrorController extends ChangeNotifier {
  final AirPlayChannel _airPlayChannel = AirPlayChannel();

  MirroringState _state = MirroringState.idle;
  String? _connectedRouteName;
  bool _isAirPlayAvailable = false;
  String? _errorMessage;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  MirroringState get state => _state;
  String? get connectedRouteName => _connectedRouteName;
  bool get isAirPlayAvailable => _isAirPlayAvailable;
  String? get errorMessage => _errorMessage;
  bool get isConnected =>
      _state == MirroringState.airPlayConnected ||
      _state == MirroringState.systemMirroringActive;

  Future<void> initialize() async {
    try {
      _isAirPlayAvailable = await _airPlayChannel.isAirPlayAvailable();
    } catch (e) {
      _log.error('Failed to check AirPlay availability', e);
      _isAirPlayAvailable = false;
    }
    notifyListeners();

    try {
      await _airPlayChannel.startMonitoring();
    } catch (e) {
      _log.error('Failed to start AirPlay monitoring', e);
    }

    _eventSubscription?.cancel();
    _eventSubscription = _airPlayChannel.events.listen(
      _onNativeEvent,
      onError: (e) {
        _log.error('AirPlay event stream error', e);
      },
    );

    await _refreshStatus();
  }

  void _onNativeEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    final data = event['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'routeChange':
      case 'routePickerClosed':
      case 'initialState':
        _updateFromStatus(data);
        break;
      case 'systemMirroringStarted':
        _state = MirroringState.systemMirroringActive;
        _connectedRouteName = data['connectedDeviceName'] as String?;
        _log.info('System mirroring started: $_connectedRouteName');
        notifyListeners();
        break;
      case 'systemMirroringStopped':
        _state = MirroringState.idle;
        _connectedRouteName = null;
        _log.info('System mirroring stopped');
        notifyListeners();
        break;
    }
  }

  void _updateFromStatus(Map<String, dynamic> status) {
    final isSystemMirroring =
        status['isSystemMirroringActive'] as bool? ?? false;
    final isAirPlayConnected = status['isAirPlayConnected'] as bool? ?? false;
    final deviceName = status['connectedDeviceName'] as String?;

    if (isSystemMirroring) {
      _state = MirroringState.systemMirroringActive;
      _connectedRouteName =
          status['mirroredScreenName'] as String? ?? deviceName;
    } else if (isAirPlayConnected) {
      _state = MirroringState.airPlayConnected;
      _connectedRouteName = deviceName;
    } else if (_isAirPlayAvailable) {
      _state = MirroringState.airPlayAvailable;
      _connectedRouteName = null;
    } else {
      _state = MirroringState.idle;
      _connectedRouteName = null;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _airPlayChannel.getMirroringStatus();
      _updateFromStatus(status);
    } catch (e) {
      _log.error('Failed to refresh AirPlay status', e);
    }
  }

  Future<bool> showRoutePicker() async {
    try {
      final result = await _airPlayChannel.showRoutePicker();
      final success = result['success'] as bool? ?? false;

      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshStatus();

      return success;
    } catch (e) {
      _log.error('showRoutePicker failed', e);
      _errorMessage = 'Could not show AirPlay device picker.';
      _state = MirroringState.error;
      notifyListeners();
      return false;
    }
  }

  String getMirroringGuide() {
    return 'To mirror your entire iPhone screen to an AirPlay receiver '
        '(like Apple TV):\n\n'
        '1. Swipe down from the top-right corner to open Control Center\n'
        '2. Tap the Screen Mirroring button (two overlapping rectangles)\n'
        '3. Select your AirPlay receiver from the list\n\n'
        'Note: This mirrors the ENTIRE iPhone screen including the home '
        'screen, other apps, and system UI. Our app cannot initiate this '
        'automatically due to iOS platform restrictions.';
  }

  Future<void> stopMirroring() async {
    _state = MirroringState.idle;
    _connectedRouteName = null;
    _errorMessage = null;
    _log.info('Mirroring stopped');
    notifyListeners();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _airPlayChannel.dispose();
    _log.info('Disposed');
    super.dispose();
  }
}
