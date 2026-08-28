import 'dart:async';
import 'package:flutter/material.dart';
import '../models/cast_device.dart';
import '../services/device_discovery_service.dart';
import '../services/real_device_discovery_service.dart';

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

  List<CastDevice> get connectedDevices => _devices
      .where((d) => d.connectionState == DeviceConnectionState.connected)
      .toList();

  List<CastDevice> get availableDevices => _devices
      .where((d) => d.connectionState == DeviceConnectionState.disconnected)
      .toList();

  List<CastDevice> get unavailableDevices => _devices
      .where((d) => d.connectionState == DeviceConnectionState.error)
      .toList();

  @override
  void initState() {
    super.initState();
    DeviceDiscoveryProvider._staticState = this;
    _service = widget.service ?? RealDeviceDiscoveryService();
    _subscription = _service.deviceStream.listen((devices) {
      setState(() {
        _devices = devices;
        _state = DiscoveryState.loaded;
      });
    });
    discoverDevices();
  }

  @override
  void dispose() {
    DeviceDiscoveryProvider._staticState = null;
    _subscription?.cancel();
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
      setState(() {
        _state = DiscoveryState.error;
        _errorMessage = 'Failed to discover devices. Please try again.';
      });
    }
  }

  Future<void> connectTo(CastDevice device) async {
    try {
      await _service.connectToDevice(device);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to \.';
      });
    }
  }

  Future<void> disconnect(CastDevice device) async {
    try {
      await _service.disconnectDevice(device);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to disconnect from \.';
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
