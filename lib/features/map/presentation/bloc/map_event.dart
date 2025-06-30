part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class GetInitialLocation extends MapEvent {
  final bool fetchOnce;
  const GetInitialLocation({this.fetchOnce = false});
  @override
  List<Object?> get props => [fetchOnce];
}

class StartLocationTracking extends MapEvent {
  const StartLocationTracking();
}

class StopLocationTracking extends MapEvent {
  const StopLocationTracking();
}

class LocationUpdated extends MapEvent {
  final Position position; // This is the geolocator Position
  const LocationUpdated(this.position);
  @override
  List<Object?> get props => [position];
}

class GetUserTraccarDevices extends MapEvent {}

class StartTraccarWebSocket extends MapEvent {}

class StopTraccarWebSocket extends MapEvent {}

class TraccarDataReceived extends MapEvent {
  final dynamic data; // Can be Map or PositionModel
  const TraccarDataReceived(this.data);
  @override
  List<Object?> get props => [data];
}

class LocationTrackingError extends MapEvent {
  final String errorMessage;
  const LocationTrackingError(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

class TraccarDeviceSelected extends MapEvent {
  final int? deviceId; // Null for 'This Device'
  const TraccarDeviceSelected(this.deviceId);
  @override
  List<Object?> get props => [deviceId];
}


class GetLastKnownLocationForDevice extends MapEvent {
  final int deviceId;
  const GetLastKnownLocationForDevice(this.deviceId);
  @override
  List<Object?> get props => [deviceId];
}

class DeleteDevice extends MapEvent {
  final int deviceId;
  const DeleteDevice(this.deviceId);
  @override
  List<Object?> get props => [deviceId];

}