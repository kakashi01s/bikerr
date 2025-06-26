part of 'map_bloc.dart';

class MapState extends Equatable {
  final Position? position;
  final PostApiStatus postApiStatus;
  final String? errorMessage;
  final List<Device>? traccarDevices;
  final dynamic webSocketData; // New field to hold WebSocket data
  final int? selectedDeviceId;
  final Map<int, LatLng> traccarDeviceLocations;

  const MapState({
    this.position,
    this.postApiStatus = PostApiStatus.initial,
    this.errorMessage,
    this.traccarDevices,
    this.webSocketData, // Initialize new field
    this.selectedDeviceId,
    this.traccarDeviceLocations = const {},

  });

  MapState copyWith({
    Position? position,
    PostApiStatus? postApiStatus,
    String? errorMessage,
    List<Device>? traccarDevices,
    dynamic webSocketData, // Update copyWith for new field
    int? selectedDeviceId,
    Map<int, LatLng>? traccarDeviceLocations,
  }) {
    return MapState(
      position: position ?? this.position,
      postApiStatus: postApiStatus ?? this.postApiStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      traccarDevices: traccarDevices ?? this.traccarDevices,
      webSocketData: webSocketData, // Allow null to clear data if needed
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
      traccarDeviceLocations: traccarDeviceLocations ?? this.traccarDeviceLocations,
    );
  }

  @override
  List<Object?> get props => [
    position,
    postApiStatus,
    errorMessage,
    traccarDevices,
    webSocketData, // Add new field to props
    selectedDeviceId,
    traccarDeviceLocations,
  ];
}