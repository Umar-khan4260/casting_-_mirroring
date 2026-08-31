import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:casting_mirroring/models/cast_device.dart';
import 'package:casting_mirroring/providers/device_discovery_provider.dart';
import 'package:casting_mirroring/services/device_discovery_service.dart';

class MockDeviceDiscoveryService extends Mock
    implements DeviceDiscoveryService {}

class _FakeCastDevice extends Fake implements CastDevice {}

void main() {
  late MockDeviceDiscoveryService mockService;
  late StreamController<List<CastDevice>> deviceStreamController;

  setUpAll(() {
    registerFallbackValue(_FakeCastDevice());
  });

  setUp(() {
    mockService = MockDeviceDiscoveryService();
    deviceStreamController = StreamController<List<CastDevice>>.broadcast();

    when(() => mockService.deviceStream)
        .thenAnswer((_) => deviceStreamController.stream);
    when(() => mockService.discoverDevices())
        .thenAnswer((_) async => <CastDevice>[]);
    when(() => mockService.connectToDevice(any())).thenAnswer((_) async {});
    when(() => mockService.disconnectDevice(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    deviceStreamController.close();
  });

  Widget buildTestWidget({DeviceDiscoveryService? service}) {
    return MaterialApp(
      home: DeviceDiscoveryProvider(
        service: service ?? mockService,
        child: const Scaffold(body: SizedBox()),
      ),
    );
  }

  DeviceDiscoveryProviderState getState(WidgetTester tester) {
    return tester.state<DeviceDiscoveryProviderState>(
      find.byType(DeviceDiscoveryProvider),
    );
  }

  group('DeviceDiscoveryProvider', () {
    testWidgets('starts in loading state then transitions to loaded',
        (tester) async {
      when(() => mockService.discoverDevices())
          .thenAnswer((_) async => <CastDevice>[]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);
      expect(state.state, DiscoveryState.loaded);
    });

    testWidgets('displays discovered devices', (tester) async {
      when(() => mockService.discoverDevices()).thenAnswer((_) async => [
            const CastDevice(
              id: '1',
              name: 'Living Room TV',
              type: DeviceType.googleCast,
              supportsMediaCasting: true,
            ),
          ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);
      expect(state.devices.length, 1);
      expect(state.devices.first.name, 'Living Room TV');
    });

    testWidgets('handles discovery error', (tester) async {
      when(() => mockService.discoverDevices())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);
      expect(state.state, DiscoveryState.error);
      expect(state.errorMessage, isNotNull);
    });

    testWidgets('tracks connected devices', (tester) async {
      when(() => mockService.discoverDevices()).thenAnswer((_) async => [
            const CastDevice(
              id: '1',
              name: 'TV',
              type: DeviceType.googleCast,
              connectionState: DeviceConnectionState.connected,
              supportsMediaCasting: true,
            ),
          ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);
      expect(state.connectedDevices.length, 1);
    });

    testWidgets('tracks available devices', (tester) async {
      when(() => mockService.discoverDevices()).thenAnswer((_) async => [
            const CastDevice(
              id: '1',
              name: 'TV',
              type: DeviceType.googleCast,
              connectionState: DeviceConnectionState.disconnected,
              supportsMediaCasting: true,
            ),
          ]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);
      expect(state.availableDevices.length, 1);
    });

    testWidgets('connectTo calls service', (tester) async {
      when(() => mockService.discoverDevices())
          .thenAnswer((_) async => <CastDevice>[]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
      );

      await state.connectTo(device);
      verify(() => mockService.connectToDevice(device)).called(1);
    });

    testWidgets('disconnect calls service', (tester) async {
      when(() => mockService.discoverDevices())
          .thenAnswer((_) async => <CastDevice>[]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
      );

      await state.disconnect(device);
      verify(() => mockService.disconnectDevice(device)).called(1);
    });

    testWidgets('stream updates are reflected in provider',
        (tester) async {
      when(() => mockService.discoverDevices())
          .thenAnswer((_) async => <CastDevice>[]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);
      expect(state.devices.length, 0);

      deviceStreamController.add([
        const CastDevice(
          id: '1',
          name: 'New Device',
          type: DeviceType.googleCast,
          supportsMediaCasting: true,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(state.devices.length, 1);
      expect(state.devices.first.name, 'New Device');
    });

    testWidgets('discovers on button tap', (tester) async {
      when(() => mockService.discoverDevices())
          .thenAnswer((_) async => <CastDevice>[]);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final state = getState(tester);

      verify(() => mockService.discoverDevices()).called(1);

      await state.discoverDevices();
      await tester.pumpAndSettle();

      verify(() => mockService.discoverDevices()).called(1);
    });
  });
}
