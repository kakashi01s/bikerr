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

// --- Core States ---

// Initial state, before any data fetching or permissions
class MapInitial extends MapState {
  const MapInitial();
}

// Generic loading state for the very first map load.
class MapLoading extends MapState {
  const MapLoading();
}

// Generic error state. Can hold the previous state to allow the UI to
// show the map with an error overlay.
class MapError extends MapState {
  final String message;
  final MapLoaded? previousState;
  const MapError({required this.message, this.previousState});
  @override
  List<Object?> get props => [message, previousState];
}

// The core 'loaded' state that holds ONLY essential real-time map-related data.
// It does NOT hold feature-specific data like the device list or reports.
class MapLoaded extends MapState {
  final Position? currentDevicePosition;
  final PositionModel? traccarDeviceLastPosition;
  final Map<int, PositionModel> traccarDevicePositions;
  final int? selectedDeviceId;
  final dynamic latestWebSocketRawData;

  const MapLoaded({
    this.currentDevicePosition,
    this.traccarDeviceLastPosition,
    this.traccarDevicePositions = const {},
    this.selectedDeviceId,
    this.latestWebSocketRawData,
  });

  MapLoaded copyWith({
    Object? currentDevicePosition = _copyWithDefault,
    Object? traccarDeviceLastPosition = _copyWithDefault,
    Map<int, PositionModel>? traccarDevicePositions,
    Object? selectedDeviceId = _copyWithDefault,
    Object? latestWebSocketRawData = _copyWithDefault,
  }) {
    return MapLoaded(
      currentDevicePosition: currentDevicePosition == _copyWithDefault
          ? this.currentDevicePosition
          : currentDevicePosition as Position?,
      traccarDeviceLastPosition: traccarDeviceLastPosition == _copyWithDefault
          ? this.traccarDeviceLastPosition
          : traccarDeviceLastPosition as PositionModel?,
      traccarDevicePositions:
      traccarDevicePositions ?? this.traccarDevicePositions,
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
    traccarDevicePositions,
  ];
}


// Traccar add device Text-field states



// --- Feature-Specific States ---

// --- User / Session ---
class TraccarLogoutLoading extends MapState {
  final MapLoaded previousState;
  const TraccarLogoutLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class TraccarLogoutLoaded extends MapState {
  final bool success;
  const TraccarLogoutLoaded({required this.success});
  @override
  List<Object> get props => [success];
}

class UpdateTraccarUserLoading extends MapState {
  final MapLoaded previousState;
  const UpdateTraccarUserLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class UpdateTraccarUserLoaded extends MapState {
  final MapLoaded previousState;
  final String? responseBody; // Can be null on failure
  const UpdateTraccarUserLoaded({required this.previousState, this.responseBody});
  @override
  List<Object?> get props => [previousState, responseBody];
}


// --- Devices ---
class TraccarDevicesLoading extends MapState {
  final MapLoaded previousState;
  const TraccarDevicesLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class TraccarDevicesLoaded extends MapState {
  final MapLoaded previousState;
  final List<Device> devices;
  const TraccarDevicesLoaded({required this.previousState, required this.devices});
  @override
  List<Object> get props => [previousState, devices];
}
// Events
class TraccarEventsLoading extends MapState {
  final MapLoaded previousState;
  const TraccarEventsLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class TraccarEventsLoaded extends MapState {
  final MapLoaded previousState;
  final List<Event> events;
  const TraccarEventsLoaded({required this.previousState, required this.events});
  @override
  List<Object> get props => [previousState, events];
}

class DeviceByIdLoading extends MapState {
  final MapLoaded previousState;
  const DeviceByIdLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class DeviceByIdLoaded extends MapState {
  final MapLoaded previousState;
  final Device? device;
  const DeviceByIdLoaded({required this.previousState, this.device});
  @override
  List<Object?> get props => [previousState, device];
}

class AddTraccarDeviceLoading extends MapState {
  final MapLoaded previousState;
  const AddTraccarDeviceLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class AddTraccarDeviceLoaded extends MapState {
  final MapLoaded previousState;
  final String? responseBody;
  const AddTraccarDeviceLoaded({required this.previousState, this.responseBody});
  @override
  List<Object?> get props => [previousState, responseBody];
}

class UpdateTraccarDeviceLoading extends MapState {
  final MapLoaded previousState;
  const UpdateTraccarDeviceLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class UpdateTraccarDeviceLoaded extends MapState {
  final MapLoaded previousState;
  final String? responseBody;
  const UpdateTraccarDeviceLoaded({required this.previousState, this.responseBody});
  @override
  List<Object?> get props => [previousState, responseBody];
}

class DeleteTraccarDeviceLoading extends MapState {
  final MapLoaded previousState;
  const DeleteTraccarDeviceLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class DeleteTraccarDeviceLoaded extends MapState {
  final MapLoaded previousState;
  final bool success;
  const DeleteTraccarDeviceLoaded({required this.previousState, required this.success});
  @override
  List<Object> get props => [previousState, success];
}



// --- Positions ---
class PositionByIdLoading extends MapState {
  final MapLoaded previousState;
  const PositionByIdLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class PositionByIdLoaded extends MapState {
  final MapLoaded previousState;
  final PositionModel? position;
  const PositionByIdLoaded({required this.previousState, this.position});
  @override
  List<Object?> get props => [previousState, position];
}

class LatestPositionsLoading extends MapState {
  final MapLoaded previousState;
  const LatestPositionsLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class LatestPositionsLoaded extends MapState {
  final MapLoaded previousState;
  final List<PositionModel> positions;
  const LatestPositionsLoaded({required this.previousState, required this.positions});
  @override
  List<Object> get props => [previousState, positions];
}


// --- Commands ---
class SendCommandsLoading extends MapState {
  final MapLoaded previousState;
  const SendCommandsLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class SendCommandsLoaded extends MapState {
  final MapLoaded previousState;
  final List<GetCommands> commandTypes;
  const SendCommandsLoaded({required this.previousState, required this.commandTypes});
  @override
  List<Object> get props => [previousState, commandTypes];
}

class SendTraccarCommandLoading extends MapState {
  final MapLoaded previousState;
  const SendTraccarCommandLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class SendTraccarCommandLoaded extends MapState {
  final MapLoaded previousState;
  final String? responseBody;
  const SendTraccarCommandLoaded({required this.previousState, this.responseBody});
  @override
  List<Object?> get props => [previousState, responseBody];
}

// --- Reports ---
class ReportLoading extends MapState {
  final MapLoaded previousState;
  const ReportLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class RouteReportLoaded extends MapState {
  final MapLoaded previousState;
  final List<RouteReport> reports;
  const RouteReportLoaded({required this.previousState, required this.reports});
  @override
  List<Object> get props => [previousState, reports];
}

class TripReportLoaded extends MapState {
  final MapLoaded previousState;
  final List<Trip> reports;
  const TripReportLoaded({required this.previousState, required this.reports});
  @override
  List<Object> get props => [previousState, reports];
}

class EventsReportLoaded extends MapState {
  final MapLoaded previousState;
  final List<Event> reports;
  const EventsReportLoaded({required this.previousState, required this.reports});
  @override
  List<Object> get props => [previousState, reports];
}

class StopsReportLoaded extends MapState {
  final MapLoaded previousState;
  final List<Stop> reports;
  const StopsReportLoaded({required this.previousState, required this.reports});
  @override
  List<Object> get props => [previousState, reports];
}

class SummaryReportLoaded extends MapState {
  final MapLoaded previousState;
  final List<PositionModel>? summary;
  const SummaryReportLoaded({required this.previousState, this.summary});
  @override
  List<Object?> get props => [previousState, summary];
}


// --- Geofences ---
class GeofencesLoading extends MapState {
  final MapLoaded previousState;
  const GeofencesLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class GeofencesLoaded extends MapState {
  final MapLoaded previousState;
  final List<GeofenceModel> geofences;
  const GeofencesLoaded({required this.previousState, required this.geofences});
  @override
  List<Object?> get props => [previousState, geofences];
}

class AddTraccarGeofenceLoading extends MapState {
  final MapLoaded previousState;
  const AddTraccarGeofenceLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class AddTraccarGeofenceLoaded extends MapState {
  final MapLoaded previousState;
  final String? responseBody;
  const AddTraccarGeofenceLoaded({required this.previousState, this.responseBody});
  @override
  List<Object?> get props => [previousState, responseBody];
}

class UpdateTraccarGeofenceLoading extends MapState {
  final MapLoaded previousState;
  const UpdateTraccarGeofenceLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class UpdateTraccarGeofenceLoaded extends MapState {
  final MapLoaded previousState;
  final String? responseBody;
  const UpdateTraccarGeofenceLoaded({required this.previousState, this.responseBody});
  @override
  List<Object?> get props => [previousState, responseBody];
}

class DeleteTraccarGeofenceLoading extends MapState {
  final MapLoaded previousState;
  const DeleteTraccarGeofenceLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class DeleteTraccarGeofenceLoaded extends MapState {
  final MapLoaded previousState;
  final bool success;
  const DeleteTraccarGeofenceLoaded({required this.previousState, required this.success});
  @override
  List<Object> get props => [previousState, success];
}

// Generic error state. Can hold the previous state to allow the UI to
// show the map with an error overlay.
class TraccarGeofenceError extends MapState {
  final String message;
  final MapLoaded? previousState;
  const TraccarGeofenceError({required this.message, this.previousState});
  @override
  List<Object?> get props => [message, previousState];
}


// --- Permissions ---
class AddTraccarPermissionLoading extends MapState {
  final MapLoaded previousState;
  const AddTraccarPermissionLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class AddTraccarPermissionLoaded extends MapState {
  final MapLoaded previousState;
  final bool success;
  const AddTraccarPermissionLoaded({required this.previousState, required this.success});
  @override
  List<Object> get props => [previousState, success];
}

class DeleteTraccarPermissionLoading extends MapState {
  final MapLoaded previousState;
  const DeleteTraccarPermissionLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class DeleteTraccarPermissionLoaded extends MapState {
  final MapLoaded previousState;
  final bool success;
  const DeleteTraccarPermissionLoaded({required this.previousState, required this.success});
  @override
  List<Object> get props => [previousState, success];
}

// --- Notifications ---
class NotificationTypesLoading extends MapState {
  final MapLoaded previousState;
  const NotificationTypesLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class NotificationTypesLoaded extends MapState {
  final MapLoaded previousState;
  final List<NotificationTypeModel> notificationTypes;
  const NotificationTypesLoaded({required this.previousState, required this.notificationTypes});
  @override
  List<Object> get props => [previousState, notificationTypes];
}

class NotificationsLoading extends MapState {
  final MapLoaded previousState;
  const NotificationsLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class NotificationsLoaded extends MapState {
  final MapLoaded previousState;
  final List<NotificationModel>? notifications;
  const NotificationsLoaded({required this.previousState, required this.notifications});
  @override
  List<Object?> get props => [previousState, notifications];
}

class AddTraccarNotificationLoading extends MapState {
  final MapLoaded previousState;
  const AddTraccarNotificationLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class AddTraccarNotificationLoaded extends MapState {
  final MapLoaded previousState;
  final String? responseBody;
  const AddTraccarNotificationLoaded({required this.previousState, this.responseBody});
  @override
  List<Object?> get props => [previousState, responseBody];
}

class DeleteTraccarNotificationLoading extends MapState {
  final MapLoaded previousState;
  const DeleteTraccarNotificationLoading({required this.previousState});
  @override
  List<Object> get props => [previousState];
}

class DeleteTraccarNotificationLoaded extends MapState {
  final MapLoaded previousState;
  final bool success;
  const DeleteTraccarNotificationLoaded({required this.previousState, required this.success});
  @override
  List<Object> get props => [previousState, success];
}