import 'dart:async';
import '../models/cast_device.dart';
import 'device_discovery_service.dart';

class MockDeviceDiscoveryService implements DeviceDiscoveryService {
  final _controller = StreamController<List<CastDevice>>.broadcast();
  List<CastDevice> _devices = [];

  static const _mockDevices = [
    CastDevice(
      id: '1',
      name: 'Living Room TV',
      type: DeviceType.googleCast,
      connectionState: DeviceConnectionState.connected,
      supportsMediaCasting: true,
      supportsScreenMirroring: true,
    ),
    CastDevice(
      id: '2',
      name: 'Bedroom Apple TV',
      type: DeviceType.appleAirPlay,
      connectionState: DeviceConnectionState.disconnected,
      supportsMediaCasting: true,
      supportsScreenMirroring: true,
    ),
    CastDevice(
      id: '3',
      name: 'Kitchen Speaker',
      type: DeviceType.unknown,
      connectionState: DeviceConnectionState.disconnected,
      supportsMediaCasting: true,
      supportsScreenMirroring: false,
    ),
  ];

  @override
  Stream<List<CastDevice>> get deviceStream => _controller.stream;

  @override
  Future<List<CastDevice>> discoverDevices() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    _devices = _mockDevices.map((d) {
      if (d.connectionState == DeviceConnectionState.connected) return d;
      if (d.connectionState == DeviceConnectionState.error) {
        return d.copyWith(connectionState: DeviceConnectionState.disconnected);
      }
      return d;
    }).toList();

    _controller.add(_devices);
    return _devices;
  }

  @override
  Future<void> connectToDevice(CastDevice device) async {
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index == -1) return;

    _devices[index] = _devices[index].copyWith(
      connectionState: DeviceConnectionState.connecting,
    );
    _controller.add(List.unmodifiable(_devices));

    await Future.delayed(const Duration(milliseconds: 2000));

    _devices[index] = _devices[index].copyWith(
      connectionState: DeviceConnectionState.connected,
    );
    _controller.add(List.unmodifiable(_devices));
  }

  @override
  Future<void> disconnectDevice(CastDevice device) async {
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index == -1) return;

    _devices[index] = _devices[index].copyWith(
      connectionState: DeviceConnectionState.disconnected,
    );
    _controller.add(List.unmodifiable(_devices));
  }

  void dispose() {
    _controller.close();
  }
}
