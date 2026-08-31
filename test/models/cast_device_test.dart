import 'package:flutter_test/flutter_test.dart';
import 'package:casting_mirroring/models/cast_device.dart';

void main() {
  group('CastDevice', () {
    test('default values are correct', () {
      const device = CastDevice(
        id: '1',
        name: 'Test',
        type: DeviceType.googleCast,
      );

      expect(device.id, '1');
      expect(device.name, 'Test');
      expect(device.type, DeviceType.googleCast);
      expect(device.connectionState, DeviceConnectionState.disconnected);
      expect(device.mirroringConnectionState, DeviceConnectionState.disconnected);
      expect(device.supportsMediaCasting, false);
      expect(device.supportsScreenMirroring, false);
    });

    group('isAnyConnected', () {
      test('returns false when both states are disconnected', () {
        const device = CastDevice(
          id: '1',
          name: 'Test',
          type: DeviceType.googleCast,
          connectionState: DeviceConnectionState.disconnected,
          mirroringConnectionState: DeviceConnectionState.disconnected,
        );
        expect(device.isAnyConnected, false);
      });

      test('returns true when media connection is connected', () {
        const device = CastDevice(
          id: '1',
          name: 'Test',
          type: DeviceType.googleCast,
          connectionState: DeviceConnectionState.connected,
          mirroringConnectionState: DeviceConnectionState.disconnected,
        );
        expect(device.isAnyConnected, true);
      });

      test('returns true when mirroring connection is connected', () {
        const device = CastDevice(
          id: '1',
          name: 'Test',
          type: DeviceType.appleAirPlay,
          connectionState: DeviceConnectionState.disconnected,
          mirroringConnectionState: DeviceConnectionState.connected,
        );
        expect(device.isAnyConnected, true);
      });

      test('returns true when both connections are connected', () {
        const device = CastDevice(
          id: '1',
          name: 'Test',
          type: DeviceType.googleCast,
          connectionState: DeviceConnectionState.connected,
          mirroringConnectionState: DeviceConnectionState.connected,
        );
        expect(device.isAnyConnected, true);
      });

      test('returns false when connecting (not yet connected)', () {
        const device = CastDevice(
          id: '1',
          name: 'Test',
          type: DeviceType.googleCast,
          connectionState: DeviceConnectionState.connecting,
          mirroringConnectionState: DeviceConnectionState.disconnected,
        );
        expect(device.isAnyConnected, false);
      });
    });

    group('copyWith', () {
      test('returns copy with updated fields', () {
        const device = CastDevice(
          id: '1',
          name: 'Test',
          type: DeviceType.googleCast,
        );

        final updated = device.copyWith(
          name: 'Updated Name',
          connectionState: DeviceConnectionState.connected,
          supportsMediaCasting: true,
        );

        expect(updated.id, '1');
        expect(updated.name, 'Updated Name');
        expect(updated.type, DeviceType.googleCast);
        expect(updated.connectionState, DeviceConnectionState.connected);
        expect(updated.supportsMediaCasting, true);
        expect(updated.supportsScreenMirroring, false);
      });

      test('returns identical copy when no params', () {
        const device = CastDevice(
          id: '1',
          name: 'Test',
          type: DeviceType.googleCast,
          supportsMediaCasting: true,
        );

        final copy = device.copyWith();
        expect(copy.id, device.id);
        expect(copy.name, device.name);
        expect(copy.supportsMediaCasting, device.supportsMediaCasting);
      });

      test('copyWith preserves mirroring state', () {
        const device = CastDevice(
          id: '1',
          name: 'Test',
          type: DeviceType.appleAirPlay,
          mirroringConnectionState: DeviceConnectionState.connected,
        );

        final updated = device.copyWith(name: 'Renamed');
        expect(updated.mirroringConnectionState, DeviceConnectionState.connected);
      });
    });

    group('DeviceType', () {
      test('has all expected values', () {
        expect(DeviceType.values.length, 3);
        expect(DeviceType.googleCast, isNotNull);
        expect(DeviceType.appleAirPlay, isNotNull);
        expect(DeviceType.unknown, isNotNull);
      });
    });

    group('DeviceConnectionState', () {
      test('has all expected values', () {
        expect(DeviceConnectionState.values.length, 5);
        expect(DeviceConnectionState.disconnected, isNotNull);
        expect(DeviceConnectionState.connecting, isNotNull);
        expect(DeviceConnectionState.connected, isNotNull);
        expect(DeviceConnectionState.disconnecting, isNotNull);
        expect(DeviceConnectionState.error, isNotNull);
      });
    });
  });
}
