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
  final bool supportsMediaCasting;
  final bool supportsScreenMirroring;

  const CastDevice({
    required this.id,
    required this.name,
    required this.type,
    this.connectionState = DeviceConnectionState.disconnected,
    this.supportsMediaCasting = false,
    this.supportsScreenMirroring = false,
  });

  CastDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DeviceConnectionState? connectionState,
    bool? supportsMediaCasting,
    bool? supportsScreenMirroring,
  }) {
    return CastDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      connectionState: connectionState ?? this.connectionState,
      supportsMediaCasting: supportsMediaCasting ?? this.supportsMediaCasting,
      supportsScreenMirroring:
          supportsScreenMirroring ?? this.supportsScreenMirroring,
    );
  }
}
