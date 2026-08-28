enum DeviceConnectionState {
  unavailable,
  available,
  connecting,
  connected,
}

class CastDevice {
  final String id;
  final String name;
  final String type;
  final DeviceConnectionState connectionState;
  final bool mediaCasting;
  final bool screenMirroring;
  final String? model;

  const CastDevice({
    required this.id,
    required this.name,
    required this.type,
    this.connectionState = DeviceConnectionState.available,
    this.mediaCasting = false,
    this.screenMirroring = false,
    this.model,
  });

  CastDevice copyWith({
    String? id,
    String? name,
    String? type,
    DeviceConnectionState? connectionState,
    bool? mediaCasting,
    bool? screenMirroring,
    String? model,
  }) {
    return CastDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      connectionState: connectionState ?? this.connectionState,
      mediaCasting: mediaCasting ?? this.mediaCasting,
      screenMirroring: screenMirroring ?? this.screenMirroring,
      model: model ?? this.model,
    );
  }

  bool get isConnected => connectionState == DeviceConnectionState.connected;
  bool get isAvailable => connectionState == DeviceConnectionState.available;
  bool get isConnecting => connectionState == DeviceConnectionState.connecting;
  bool get isUnavailable => connectionState == DeviceConnectionState.unavailable;

  bool get hasAnyCapability => mediaCasting || screenMirroring;
}
