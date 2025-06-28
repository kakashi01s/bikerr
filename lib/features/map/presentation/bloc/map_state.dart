part of 'map_bloc.dart';

// A private sentinel class to differentiate between a value not being passed
// and a value being passed as null.
class _CopyWithDefault {
  const _CopyWithDefault();
}

const _copyWithDefault = _CopyWithDefault();

// Base sealed class for all map states
sealed class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

// Initial state, before any data fetching or permissions
class MapInitial extends MapState {
  const MapInitial();
  @override
  List<Object?> get props => [];
}

// State for when operations are in progress
class MapLoading extends MapState {
  final String message;
  final MapLoaded? previousState;
  const MapLoading({this.message = 'Loading map data...', this.previousState});
  @override
  List<Object?> get props => [message, previousState];
}

// State for when an error occurs
class MapError extends MapState {
  final String message;
  final MapLoaded? previousState;
  const MapError({required this.message, this.previousState});
  @override
  List<Object?> get props => [message, previousState];
}

// This is the core 'loaded' state that holds all your map-related data.
class MapLoaded extends MapState {
  // 'This Device' location (nullable because it might not be available or selected)
  final Position? currentDevicePosition;
  final Map<int, LatLng> traccarDeviceLocations; // All known Traccar locations
  final List<Device> traccarDevices; // All fetched Traccar devices
  final int? selectedDeviceId; // null means 'This Device' is selected
  final dynamic latestWebSocketRawData; // For debugging/displaying raw WebSocket data

  const MapLoaded({
    this.currentDevicePosition,
    this.traccarDeviceLocations = const {},
    this.traccarDevices = const [],
    this.selectedDeviceId,
    this.latestWebSocketRawData,
  });

  // copyWith for the MapLoaded state only
  MapLoaded copyWith({
    // For nullable fields, we use the sentinel to detect if a value was passed.
    Object? currentDevicePosition = _copyWithDefault,
    Map<int, LatLng>? traccarDeviceLocations,
    List<Device>? traccarDevices,
    Object? selectedDeviceId = _copyWithDefault,
    Object? latestWebSocketRawData = _copyWithDefault,
  }) {
    return MapLoaded(
      // If the passed value is the sentinel, keep the old value.
      // Otherwise, use the new value (even if it's null).
      currentDevicePosition: currentDevicePosition == _copyWithDefault
          ? this.currentDevicePosition
          : currentDevicePosition as Position?,

      // For non-nullable fields with defaults, the ?? operator is fine.
      traccarDeviceLocations:
      traccarDeviceLocations ?? this.traccarDeviceLocations,
      traccarDevices: traccarDevices ?? this.traccarDevices,

      // Apply the sentinel check for the other nullable fields.
      selectedDeviceId: selectedDeviceId == _copyWithDefault
          ? this.selectedDeviceId
          : selectedDeviceId as int?,
      latestWebSocketRawData: latestWebSocketRawData == _copyWithDefault
          ? this.latestWebSocketRawData
          : latestWebSocketRawData,
    );
  }

  @override
  List<Object?> get props => [
    currentDevicePosition,
    traccarDeviceLocations,
    traccarDevices,
    selectedDeviceId,
    latestWebSocketRawData,
  ];
}