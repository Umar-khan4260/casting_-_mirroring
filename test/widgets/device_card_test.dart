import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/models/cast_device.dart';
import 'package:casting_mirroring/widgets/cards/device_card.dart';

void main() {
  Widget wrapInApp(Widget child) => MaterialApp(
        home: Scaffold(body: child),
      );

  group('DeviceCard', () {
    testWidgets('displays device name', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'Living Room TV',
        type: DeviceType.googleCast,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.text('Living Room TV'), findsOneWidget);
    });

    testWidgets('shows cast icon for Google Cast device', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.byIcon(Icons.cast), findsOneWidget);
    });

    testWidgets('shows airplay icon for AirPlay device', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'Apple TV',
        type: DeviceType.appleAirPlay,
        supportsScreenMirroring: true,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.byIcon(Icons.airplay), findsOneWidget);
    });

    testWidgets('shows connected badge when connected', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('shows check_circle for mirroring connected device', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'Apple TV',
        type: DeviceType.appleAirPlay,
        mirroringConnectionState: DeviceConnectionState.connected,
        supportsScreenMirroring: true,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('shows capabilities section when device supports features', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        supportsMediaCasting: true,
        supportsScreenMirroring: true,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.text('Media Casting'), findsOneWidget);
      expect(find.text('Screen Mirroring'), findsOneWidget);
    });

    testWidgets('does not show capabilities when none supported', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.unknown,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.text('Media Casting'), findsNothing);
      expect(find.text('Screen Mirroring'), findsNothing);
    });

    testWidgets('tapping calls onTap callback', (tester) async {
      bool tapped = false;
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceCard(
          device: device,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(DeviceCard));
      expect(tapped, true);
    });

    testWidgets('tapping is disabled when connecting', (tester) async {
      bool tapped = false;
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connecting,
      );

      await tester.pumpWidget(wrapInApp(
        DeviceCard(
          device: device,
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.byType(DeviceCard));
      expect(tapped, false);
    });

    testWidgets('shows connecting indicator when connecting', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connecting,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows media casting connected status', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'TV',
        type: DeviceType.googleCast,
        connectionState: DeviceConnectionState.connected,
        supportsMediaCasting: true,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.text('Media casting'), findsOneWidget);
    });

    testWidgets('shows mirroring connected status', (tester) async {
      const device = CastDevice(
        id: '1',
        name: 'Apple TV',
        type: DeviceType.appleAirPlay,
        mirroringConnectionState: DeviceConnectionState.connected,
        supportsScreenMirroring: true,
      );

      await tester.pumpWidget(wrapInApp(const DeviceCard(device: device)));
      expect(find.text('Screen mirroring'), findsOneWidget);
    });
  });
}
