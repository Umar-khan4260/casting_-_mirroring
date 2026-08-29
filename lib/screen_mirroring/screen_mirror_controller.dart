import 'dart:async';
import 'package:flutter/foundation.dart';
import '../casting_core/interfaces/screen_mirroring_interface.dart';
import 'air_play_channel.dart';

/// Controller for screen mirroring state management.
///
/// This controller exposes the AirPlay mirroring state to the Flutter UI.
/// It communicates with the native iOS AirPlayPlugin via [AirPlayChannel].
///
/// ## iOS Platform Limitation
///
/// **Third-party apps CANNOT programmatically initiate full-device AirPlay mirroring.**
/// The user must manually go to Control Center → Screen Mirroring to mirror
/// the entire iPhone screen (home screen, other apps, system UI).
///
/// What this controller supports:
/// - Detecting AirPlay route availability
/// - Presenting the system AirPlay route picker (for media routing)
/// - Detecting when system-level screen mirroring is active (user-initiated)
/// - Tracking connection state
///
/// For full-device mirroring guidance, see [showMirroringGuide].
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

  /// Initialize the controller and start monitoring AirPlay state.
  Future<void> initialize() async {
    _isAirPlayAvailable = await _airPlayChannel.isAirPlayAvailable();
    notifyListeners();

    await _airPlayChannel.startMonitoring();

    _eventSubscription = _airPlayChannel.events.listen(_onNativeEvent);

    // Get initial status
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
        notifyListeners();
        break;
      case 'systemMirroringStopped':
        _state = MirroringState.idle;
        _connectedRouteName = null;
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
      _connectedRouteName = status['mirroredScreenName'] as String? ?? deviceName;
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

    notifyListeners();
  }

  Future<void> _refreshStatus() async {
    final status = await _airPlayChannel.getMirroringStatus();
    _updateFromStatus(status);
  }

  /// Show the system AirPlay route picker.
  ///
  /// This presents the standard iOS AVRoutePickerView where the user can
  /// select an AirPlay receiver. On Apple TV, this enables media routing.
  ///
  /// NOTE: This routes media content (video/audio) to the AirPlay receiver.
  /// For full-device screen mirroring, the user must use Control Center.
  Future<bool> showRoutePicker() async {
    try {
      final result = await _airPlayChannel.showRoutePicker();
      final success = result['success'] as bool? ?? false;

      // Refresh status after picker is dismissed
      await Future.delayed(const Duration(milliseconds: 500));
      await _refreshStatus();

      return success;
    } catch (e) {
      _errorMessage = 'Failed to show route picker: $e';
      _state = MirroringState.error;
      notifyListeners();
      return false;
    }
  }

  /// Get a user-friendly guide for enabling full-device screen mirroring.
  ///
  /// Since iOS does not allow third-party apps to initiate AirPlay mirroring,
  /// this returns instructions the user can follow manually.
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

  /// Stop any active mirroring connection.
  Future<void> stopMirroring() async {
    _state = MirroringState.idle;
    _connectedRouteName = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Dispose resources.
  @override
  void dispose() {
    _eventSubscription?.cancel();
    _airPlayChannel.dispose();
    super.dispose();
  }
}
