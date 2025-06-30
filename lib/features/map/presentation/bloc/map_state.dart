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

class LoadingDevices extends MapState {
  final String message;
  final MapLoaded? previousState;
  const LoadingDevices({this.message = 'Loading Devices data...', this.previousState});
  @override
  List<Object?> get props => [message, previousState];
}

class TraccarDevicesLoaded extends MapState {
  final List<Device> traccarDevices;
  final MapLoaded? previousState; // <-- ADD THIS LINE

  const TraccarDevicesLoaded({
    this.traccarDevices = const [],
    this.previousState, // <-- ADD THIS LINE
  });

  TraccarDevicesLoaded copyWith({
    List<Device>? traccarDevices,
    MapLoaded? previousState, // <-- ADD THIS LINE
  }) {
    return TraccarDevicesLoaded(
      traccarDevices: traccarDevices ?? this.traccarDevices,
      previousState: previousState ?? this.previousState, // <-- ADD THIS LINE
    );
  }

  @override
  List<Object?> get props => [traccarDevices, previousState]; // <-- UPDATE THIS LINE
}


// This is the core 'loaded' state that holds all your map-related data.
class MapLoaded extends MapState {
  // 'This Device' location (nullable because it might not be available or selected)
  final Map<int, PositionModel> traccarDevicePositions;
  final Position? currentDevicePosition;
  final PositionModel? traccarDeviceLastPosition; // All known Traccar locations
  final int? selectedDeviceId; // null means 'This Device' is selected
  final dynamic latestWebSocketRawData; // For debugging/displaying raw WebSocket data

  const MapLoaded({
    this.traccarDevicePositions = const {},
    this.currentDevicePosition,
    this.traccarDeviceLastPosition,
    this.selectedDeviceId,
    this.latestWebSocketRawData,
  });

  // copyWith for the MapLoaded state only
  MapLoaded copyWith({
    // For nullable fields, we use the sentinel to detect if a value was passed.
    Object? currentDevicePosition = _copyWithDefault,
    Object? traccarDeviceLastPosition = _copyWithDefault,
    Map<int, PositionModel>? traccarDevicePositions,
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
      traccarDeviceLastPosition:
      traccarDeviceLastPosition == _copyWithDefault ? this.traccarDeviceLastPosition : traccarDeviceLastPosition as PositionModel?,
      traccarDevicePositions: traccarDevicePositions ?? this.traccarDevicePositions,

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
    traccarDeviceLastPosition,
    selectedDeviceId,
    latestWebSocketRawData,
    traccarDevicePositions
  ];
}