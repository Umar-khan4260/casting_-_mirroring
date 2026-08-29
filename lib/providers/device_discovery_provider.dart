import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cast_device.dart';
import '../services/device_discovery_service.dart';
import '../services/real_device_discovery_service.dart';
import '../utils/cast_logger.dart';

const _log = CastLogger('DiscoveryProvider');

enum DiscoveryState { idle, loading, loaded, error }

class DeviceDiscoveryProvider extends StatefulWidget {
  final Widget child;
  final DeviceDiscoveryService? service;

  const DeviceDiscoveryProvider({Key? key, required this.child, this.service})
    : super(key: key);

  static DeviceDiscoveryProviderState? _staticState;

  static DeviceDiscoveryProviderState of(BuildContext context) {
    if (_staticState != null) return _staticState!;

    final provider = context
        .dependOnInheritedWidgetOfExactType<_DeviceDiscoveryInherited>();
    if (provider != null) return provider.state;

    throw FlutterError.fromParts([
      ErrorSummary('DeviceDiscoveryProvider not found'),
      ErrorDescription(
        'No DeviceDiscoveryProvider found in the widget tree. '
        'Wrap your app with DeviceDiscoveryProvider.',
      ),
    ]);
  }

  @override
  State<DeviceDiscoveryProvider> createState() =>
      DeviceDiscoveryProviderState();
}

class DeviceDiscoveryProviderState extends State<DeviceDiscoveryProvider> {
  late final DeviceDiscoveryService _service;
  DiscoveryState _state = DiscoveryState.idle;
  List<CastDevice> _devices = [];
  String? _errorMessage;
  StreamSubscription<List<CastDevice>>? _subscription;

  DiscoveryState get state => _state;
  List<CastDevice> get devices => _devices;
  String? get errorMessage => _errorMessage;

  List<CastDevice> get connectedDevices =>
      _devices.where((d) => d.isAnyConnected).toList();

  List<CastDevice> get availableDevices => _devices
      .where((d) =>
          !d.isAnyConnected &&
          d.connectionState == DeviceConnectionState.disconnected)
      .toList();

  List<CastDevice> get unavailableDevices => _devices
      .where((d) => d.connectionState == DeviceConnectionState.error)
      .toList();

  @override
  void initState() {
    super.initState();
    DeviceDiscoveryProvider._staticState = this;
    _service = widget.service ?? RealDeviceDiscoveryService();
    _subscription = _service.deviceStream.listen(
      (devices) {
        _log.debug('Received ${devices.length} device(s) from stream');
        if (mounted) {
          setState(() {
            _devices = devices;
            _state = DiscoveryState.loaded;
            _errorMessage = null;
          });
        }
      },
      onError: (e) {
        _log.error('Device stream error', e);
        if (mounted) {
          setState(() {
            _state = DiscoveryState.error;
            _errorMessage = 'Device discovery lost connection. Please try again.';
          });
        }
      },
    );
    discoverDevices();
  }

  @override
  void dispose() {
    DeviceDiscoveryProvider._staticState = null;
    _subscription?.cancel();
    _subscription = null;
    final service = _service;
    if (service is RealDeviceDiscoveryService) {
      service.dispose();
    }
    super.dispose();
  }

  Future<void> discoverDevices() async {
    setState(() {
      _state = DiscoveryState.loading;
      _errorMessage = null;
    });

    try {
      _devices = await _service.discoverDevices();
      setState(() {
        _state = DiscoveryState.loaded;
      });
    } catch (e) {
      _log.error('discoverDevices failed', e);
      setState(() {
        _state = DiscoveryState.error;
        if (e.toString().contains('network') ||
            e.toString().contains('permission')) {
          _errorMessage =
              'Local network access is required. Please enable it in Settings.';
        } else {
          _errorMessage = 'No devices found. Make sure your device is on the same Wi-Fi network.';
        }
      });
    }
  }

  Future<void> connectTo(CastDevice device) async {
    try {
      await _service.connectToDevice(device);
    } catch (e) {
      _log.error('connectTo failed', e);
      setState(() {
        if (e.toString().contains('timed out')) {
          _errorMessage =
              '${device.name} is not responding. It may be unavailable or too far away.';
        } else if (e.toString().contains('not found')) {
          _errorMessage =
              '${device.name} is no longer available on the network.';
        } else {
          _errorMessage = 'Could not connect to ${device.name}. Please try again.';
        }
      });
    }
  }

  Future<void> disconnect(CastDevice device) async {
    try {
      await _service.disconnectDevice(device);
    } catch (e) {
      _log.error('disconnect failed', e);
      setState(() {
        _errorMessage = 'Could not disconnect from ${device.name}. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DeviceDiscoveryInherited(state: this, child: widget.child);
  }
}

class _DeviceDiscoveryInherited extends InheritedWidget {
  final DeviceDiscoveryProviderState state;

  const _DeviceDiscoveryInherited({required this.state, required super.child});

  @override
  bool updateShouldNotify(_DeviceDiscoveryInherited oldWidget) {
    return state != oldWidget.state;
  }
}
