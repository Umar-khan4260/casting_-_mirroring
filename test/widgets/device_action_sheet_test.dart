import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/models/cast_device.dart';
import 'package:casting_mirroring/widgets/sheets/device_action_sheet.dart';

void main() {
  Widget wrapInApp(Widget child) => MaterialApp(
        home: Scaffold(body: child),
      );

  group('DeviceActionSheet', () {
    testWidgets('shows device name', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'Living Room TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onCastMedia: () {},
          onDisconnect: () {},
        ),
      ));

      expect(find.text('Living Room TV'), findsOneWidget);
    });

    testWidgets('shows Cast Media action when supported', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onCastMedia: () {},
          onDisconnect: () {},
        ),
      ));

      expect(find.text('Cast Media'), findsOneWidget);
    });

    testWidgets('hides Cast Media when onCastMedia is null', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onCastMedia: null,
          onDisconnect: () {},
        ),
      ));

      expect(find.text('Cast Media'), findsNothing);
    });

    testWidgets('shows Mirror Screen action when supported', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'Apple TV',
        type: DeviceType.appleAirPlay,
        connectionState: DeviceConnectionState.connected,
        mirroringConnectionState: DeviceConnectionState.connected,
        supportsScreenMirroring: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onMirrorScreen: () {},
          onDisconnect: () {},
        ),
      ));

      expect(find.text('Mirror Screen'), findsOneWidget);
    });

    testWidgets('hides Mirror Screen when onMirrorScreen is null', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'Apple TV',
        type: DeviceType.appleAirPlay,
        connectionState: DeviceConnectionState.connected,
        mirroringConnectionState: DeviceConnectionState.connected,
        supportsScreenMirroring: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onMirrorScreen: null,
          onDisconnect: () {},
        ),
      ));

      expect(find.text('Mirror Screen'), findsNothing);
    });

    testWidgets('shows Disconnect button when connected', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onCastMedia: () {},
          onDisconnect: () {},
        ),
      ));

      expect(find.text('Disconnect'), findsOneWidget);
    });

    testWidgets('tapping Cast Media calls callback', (tester) async {
      bool castCalled = false;
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onCastMedia: () => castCalled = true,
          onDisconnect: () {},
        ),
      ));

      await tester.tap(find.text('Cast Media'));
      expect(castCalled, true);
    });

    testWidgets('tapping Disconnect calls callback', (tester) async {
      bool disconnectCalled = false;
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onCastMedia: () {},
          onDisconnect: () => disconnectCalled = true,
        ),
      ));

      await tester.tap(find.text('Disconnect'));
      expect(disconnectCalled, true);
    });

    testWidgets('shows Connected status', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onCastMedia: () {},
          onDisconnect: () {},
        ),
      ));

      expect(find.text('Connected'), findsOneWidget);
    });

    testWidgets('shows device info for AirPlay device', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'Apple TV',
        type: DeviceType.appleAirPlay,
        connectionState: DeviceConnectionState.connected,
        mirroringConnectionState: DeviceConnectionState.connected,
        supportsScreenMirroring: true,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceActionSheet(
          device: device,
          onMirrorScreen: () {},
          onDisconnect: () {},
        ),
      ));

      expect(find.text('Apple TV'), findsOneWidget);
      expect(find.text('Mirror Screen'), findsOneWidget);
    });
  });
}
