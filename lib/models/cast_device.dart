enum DeviceType { googleCast, appleAirPlay, unknown }

enum DeviceConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class CastDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DeviceConnectionState connectionState;
  final DeviceConnectionState mirroringConnectionState;
  final bool supportsMediaCasting;
  final bool supportsScreenMirroring;

  const CastDevice({
    required this.id,
    required this.name,
    required this.type,
    this.connectionState = DeviceConnectionState.disconnected,
    this.mirroringConnectionState = DeviceConnectionState.disconnected,
    this.supportsMediaCasting = false,
    this.supportsScreenMirroring = false,
  });

  CastDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DeviceConnectionState? connectionState,
    DeviceConnectionState? mirroringConnectionState,
    bool? supportsMediaCasting,
    bool? supportsScreenMirroring,
  }) {
    return CastDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      connectionState: connectionState ?? this.connectionState,
      mirroringConnectionState:
          mirroringConnectionState ?? this.mirroringConnectionState,
      supportsMediaCasting: supportsMediaCasting ?? this.supportsMediaCasting,
      supportsScreenMirroring:
          supportsScreenMirroring ?? this.supportsScreenMirroring,
    );
  }

  bool get isAnyConnected =>
      connectionState == DeviceConnectionState.connected ||
      mirroringConnectionState == DeviceConnectionState.connected;
}
