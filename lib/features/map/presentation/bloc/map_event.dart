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
  final Position position;
  const LocationUpdated(this.position);
  @override
  List<Object?> get props => [position];
}

class LocationTrackingError extends MapEvent {
  final String errorMessage;
  const LocationTrackingError(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}

// -- Traccar General --
class TraccarDataReceived extends MapEvent {
  final dynamic data;
  const TraccarDataReceived(this.data);
  @override
  List<Object?> get props => [data];
}

class StartTraccarWebSocket extends MapEvent {}

class StopTraccarWebSocket extends MapEvent {}

// -- Traccar Device Events --
class GetUserTraccarDevices extends MapEvent {}

class GetTraccarDeviceById extends MapEvent {
  final String id;
  const GetTraccarDeviceById(this.id);
  @override
  List<Object?> get props => [id];
}

class AddTraccarDevice extends MapEvent {
  final String deviceJson;
  const AddTraccarDevice(this.deviceJson);
  @override
  List<Object?> get props => [deviceJson];
}

class UpdateTraccarDevice extends MapEvent {
  final String deviceJson;
  final String id;
  const UpdateTraccarDevice(this.deviceJson, this.id);
  @override
  List<Object?> get props => [deviceJson, id];
}

class DeleteTraccarDevice extends MapEvent {
  final int deviceId;
  const DeleteTraccarDevice(this.deviceId);
  @override
  List<Object?> get props => [deviceId];
}

class TraccarDeviceSelected extends MapEvent {
  final int? deviceId; // Null for 'This Device'
  const TraccarDeviceSelected(this.deviceId);
  @override
  List<Object?> get props => [deviceId];
}


// -- Traccar Position Events --
class GetTraccarPositions extends MapEvent {
  final String deviceId;
  final String from;
  final String to;
  const GetTraccarPositions(this.deviceId, this.from, this.to);
  @override
  List<Object?> get props => [deviceId, from, to];
}

class GetLatestTraccarPositions extends MapEvent {}

class GetLastKnownLocationForDevice extends MapEvent {
  final int deviceId;
  const GetLastKnownLocationForDevice(this.deviceId);
  @override
  List<Object?> get props => [deviceId];
}

// -- Traccar Command Events --
class GetTraccarSendCommands extends MapEvent {
  final String id;

  const GetTraccarSendCommands(this.id);
  @override
  List<Object?> get props => [id];
}

class SendTraccarCommand extends MapEvent {
  final String commandJson;
  const SendTraccarCommand(this.commandJson);
  @override
  List<Object?> get props => [commandJson];
}

// -- Traccar Report Events --
class GetTraccarRouteReport extends MapEvent {
  final int deviceId;
  final String from;
  final String to;
  const GetTraccarRouteReport(this.deviceId, this.from, this.to);
  @override
  List<Object?> get props => [deviceId, from, to];
}



class GetTraccarEventsReport extends MapEvent {
  final String deviceId;
  final String from;
  final String to;
  const GetTraccarEventsReport(this.deviceId, this.from, this.to);
  @override
  List<Object?> get props => [deviceId, from, to];
}

class GetTraccarTripReport extends MapEvent {
  final String deviceId;
  final String from;
  final String to;
  const GetTraccarTripReport(this.deviceId, this.from, this.to);
  @override
  List<Object?> get props => [deviceId, from, to];
}

class GetTraccarStopsReport extends MapEvent {
  final String deviceId;
  final String from;
  final String to;
  const GetTraccarStopsReport(this.deviceId, this.from, this.to);
  @override
  List<Object?> get props => [deviceId, from, to];
}

class GetTraccarSummaryReport extends MapEvent {
  final String deviceId;
  final String from;
  final String to;
  const GetTraccarSummaryReport(this.deviceId, this.from, this.to);
  @override
  List<Object?> get props => [deviceId, from, to];
}


// -- Traccar User/Session Events --
class LogoutTraccar extends MapEvent {}

class UpdateTraccarUser extends MapEvent {
  final String userJson;
  final String id;
  const UpdateTraccarUser(this.userJson, this.id);
  @override
  List<Object?> get props => [userJson, id];
}

// -- Traccar Permission Events --
class AddTraccarPermission extends MapEvent {
  final String permissionJson;
  const AddTraccarPermission(this.permissionJson);
  @override
  List<Object?> get props => [permissionJson];
}

class DeleteTraccarPermission extends MapEvent {
  final String permissionJson;
  const DeleteTraccarPermission(this.permissionJson);
  @override
  List<Object?> get props => [permissionJson];
}


// -- Traccar Geofence Events --
class AddTraccarGeofence extends MapEvent {
  final String deviceId;
  final String geofenceJson;
  const AddTraccarGeofence(this.geofenceJson, this.deviceId);
  @override
  List<Object?> get props => [geofenceJson];
}

class UpdateTraccarGeofence extends MapEvent {
  final String geofenceJson;
  final String id;
  const UpdateTraccarGeofence(this.geofenceJson, this.id);
  @override
  List<Object?> get props => [geofenceJson, id];
}

class DeleteTraccarGeofence extends MapEvent {
  final String id;
  const DeleteTraccarGeofence(this.id);
  @override
  List<Object?> get props => [id];
}

class GetTraccarGeofencesByUserId extends MapEvent {
  final String userId;
  const GetTraccarGeofencesByUserId(this.userId);
  @override
  List<Object?> get props => [userId];
}

class GetTraccarGeofencesByDeviceId extends MapEvent {
  final int deviceId;
  const GetTraccarGeofencesByDeviceId(this.deviceId);
  @override
  List<Object?> get props => [deviceId];
}


// -- Traccar Notification Events --
class GetTraccarNotificationTypes extends MapEvent {}

class AddTraccarNotification extends MapEvent {
  final String notificationJson;
  const AddTraccarNotification(this.notificationJson);
  @override
  List<Object?> get props => [notificationJson];
}

class DeleteTraccarNotification extends MapEvent {
  final String id;
  const DeleteTraccarNotification(this.id);
  @override
  List<Object?> get props => [id];
}

class GetTraccarNotifications extends MapEvent {

  const GetTraccarNotifications();
  @override
  List<Object?> get props => [];
}