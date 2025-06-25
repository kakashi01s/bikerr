part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}
class LocationTrackingError extends MapEvent {
  final String errorMessage;

  const LocationTrackingError(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
class GetInitialLocation extends MapEvent {
  final bool fetchOnce; // Added fetchOnce property

  const GetInitialLocation({this.fetchOnce = true}); // Default to true

  @override
  List<Object?> get props => [fetchOnce];
}

class StartLocationTracking extends MapEvent {}

class StopLocationTracking extends MapEvent {}

class GetUserTraccarDevices extends MapEvent {}

class LocationUpdated extends MapEvent {
  final Position position;

  const LocationUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

// New events for Traccar WebSocket integration
class StartTraccarWebSocket extends MapEvent {}

class StopTraccarWebSocket extends MapEvent {}

class TraccarDataReceived extends MapEvent {
  final dynamic data; // Can be a Device, PositionModel, Event, etc.

  const TraccarDataReceived(this.data);

  @override
  List<Object?> get props => [data];
}