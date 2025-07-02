import 'dart:async';
import 'dart:convert';
import 'package:bikerr/services/session/session_manager.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';
import 'package:bikerr/features/map/domain/usecases/get_current_location_usecase.dart';

import '../../../../services/notifications/notification_service.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final session = SessionManager.instance;
  final GetCurrentLocationUsecase getCurrentLocationUsecase;
  final NotificationService notificationService;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<dynamic>? _webSocketSubscription;

  // Internal cache for the device list to be accessible across different states.
  List<Device> _devices = [];

  MapBloc(this.getCurrentLocationUsecase, this.notificationService) : super(const MapInitial()) {
    // Register all event handlers
    on<GetInitialLocation>(_onGetInitialLocation);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<LocationUpdated>(_onLocationUpdated);
    on<LocationTrackingError>(_onLocationTrackingError);
    on<StartTraccarWebSocket>(_onStartTraccarWebSocket);
    on<StopTraccarWebSocket>(_onStopTraccarWebSocket);
    on<TraccarDataReceived>(_onTraccarDataReceived);
    on<TraccarDeviceSelected>(_onTraccarDeviceSelected);

    // --- User / Session ---
    on<LogoutTraccar>(_onLogoutTraccar);
    on<UpdateTraccarUser>(_onUpdateTraccarUser);

    // --- Devices ---
    on<GetUserTraccarDevices>(_onGetUserDevices);
    on<GetTraccarDeviceById>(_onGetTraccarDeviceById);
    on<AddTraccarDevice>(_onAddTraccarDevice);
    on<UpdateTraccarDevice>(_onUpdateTraccarDevice);
    on<DeleteTraccarDevice>(_onDeleteTraccarDevice);

    // --- Positions ---
    on<GetLastKnownLocationForDevice>(_onGetLastKnownLocationForDevice);
    on<GetTraccarPositions>(_onGetTraccarPositions);
    on<GetLatestTraccarPositions>(_onGetLatestTraccarPositions);

    // --- Commands ---
    on<GetTraccarSendCommands>(_onGetTraccarSendCommands);
    on<SendTraccarCommand>(_onSendTraccarCommand);

    // --- Reports ---
    on<GetTraccarRouteReport>(_onGetTraccarRouteReport);
    on<GetTraccarEventsReport>(_onGetTraccarEventsReport);
    on<GetTraccarTripReport>(_onGetTraccarTripReport);
    on<GetTraccarStopsReport>(_onGetTraccarStopsReport);
    on<GetTraccarSummaryReport>(_onGetTraccarSummaryReport);

    // --- Permissions ---
    on<AddTraccarPermission>(_onAddTraccarPermission);
    on<DeleteTraccarPermission>(_onDeleteTraccarPermission);

    // --- Geofences ---
    on<GetTraccarGeofencesByUserId>(_onGetTraccarGeofencesByUserId);
    on<GetTraccarGeofencesByDeviceId>(_onGetTraccarGeofencesByDeviceId);
    on<AddTraccarGeofence>(_onAddTraccarGeofence);
    on<UpdateTraccarGeofence>(_onUpdateTraccarGeofence);
    on<DeleteTraccarGeofence>(_onDeleteTraccarGeofence);

    // --- Notifications ---
    on<GetTraccarNotificationTypes>(_onGetTraccarNotificationTypes);
    on<GetTraccarNotifications>(_onGetTraccarNotifications);
    on<AddTraccarNotification>(_onAddTraccarNotification);
    on<DeleteTraccarNotification>(_onDeleteTraccarNotification);
  }

  /// Helper to get the last known core MapLoaded state from any feature state.
  MapLoaded _getLoadedState() {

    final s = state;
    if (s is MapLoaded) return s;
    if (s is MapError && s.previousState != null) return s.previousState!;
    // --- Loading States ---
    if (s is TraccarDevicesLoading) return s.previousState;
    if (s is ReportLoading) return s.previousState;
    if (s is GeofencesLoading) return s.previousState;
    if (s is DeleteTraccarDeviceLoading) return s.previousState;
    // --- Loaded States ---
    if (s is TraccarDevicesLoaded) return s.previousState;
    if (s is RouteReportLoaded) return s.previousState;
    if (s is GeofencesLoaded) return s.previousState;
    if (s is TripReportLoaded) return s.previousState;
    if (s is EventsReportLoaded) return s.previousState;
    if (s is StopsReportLoaded) return s.previousState;
    if (s is SummaryReportLoaded) return s.previousState;
    if (s is PositionByIdLoaded) return s.previousState;
    if (s is LatestPositionsLoaded) return s.previousState;
    if (s is DeleteTraccarDeviceLoaded) return s.previousState;
    if (s is NotificationsLoaded) return s.previousState;

    print('[MapBoc]  state  ${s}');
    return const MapLoaded();

  }

  // --- Core Lifecycle and Position Handlers ---

  Future<void> _onGetInitialLocation(GetInitialLocation event, Emitter<MapState> emit) async {
    if (state is MapLoaded && !event.fetchOnce) return;
    emit(const MapLoading());
    final hasPermission = await _checkLocationPermission(emit);
    if (!hasPermission) return;

    try {
      final initialPositionResult = await getCurrentLocationUsecase.getLocation();
      initialPositionResult.fold(
            (error) => emit(MapError(message: error)),
            (position) {
          emit(MapLoaded(currentDevicePosition: position));
          add(const StartLocationTracking());
          add(GetUserTraccarDevices()); // Fetch devices right away
          add(StartTraccarWebSocket());
        },
      );
    } catch (e) {
      emit(MapError(message: e.toString()));
    }
  }

  void _onLocationUpdated(LocationUpdated event, Emitter<MapState> emit) {
    emit(_getLoadedState().copyWith(currentDevicePosition: event.position));
  }

  Future<void> _onTraccarDataReceived(TraccarDataReceived event, Emitter<MapState> emit) async {
    print("[MapBloc]  Traccar data received ${event.data}");
    final currentLoadedState = _getLoadedState();
    final data = event.data;

    if (data is PositionModel) {
      final newPositions = Map<int, PositionModel>.from(currentLoadedState.traccarDevicePositions);
      newPositions[data.deviceId!] = data;
      emit(currentLoadedState.copyWith(
        traccarDevicePositions: newPositions,
        traccarDeviceLastPosition: data.deviceId == currentLoadedState.selectedDeviceId ? data : currentLoadedState.traccarDeviceLastPosition,
        latestWebSocketRawData: data,
      ));
    } else if (data is Device) {
      final index = _devices.indexWhere((d) => d.id == data.id);
      if (index != -1) {
        _devices[index] = data;
      } else {
        _devices.add(data);
      }
      // If the current state is one that shows devices, update it.
      if (state is TraccarDevicesLoaded) {
        emit(TraccarDevicesLoaded(previousState: currentLoadedState, devices: List<Device>.from(_devices)));
      }
    }
    else if (data is Event) {
      print('[MapBloc]  Single Event data Received  $data');
    } else if (data is List<Event>) {
      for (var event in data) {
        print('[MapBloc]  List Event data Received  $event');
        emit(TraccarEventsLoaded(previousState: currentLoadedState, events: data));
        emit(currentLoadedState);
        // await notificationService.showNotification(
        //   RemoteMessage(data: <>)
        // );
      }
    }
  }

  // --- User / Session Event Handlers ---

  Future<void> _onLogoutTraccar(LogoutTraccar event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(TraccarLogoutLoading(previousState: currentMapState));
    try {
      final success = await Traccar.sessionLogout();
      emit(TraccarLogoutLoaded(success: success));
    } catch (e) {
      emit(MapError(message: 'Failed to logout: $e', previousState: currentMapState));
    }
  }

  Future<void> _onUpdateTraccarUser(UpdateTraccarUser event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(UpdateTraccarUserLoading(previousState: currentMapState));
    try {
      final result = await Traccar.updateUser(event.userJson, event.id);
      emit(UpdateTraccarUserLoaded(previousState: currentMapState, responseBody: result));
    } catch (e) {
      emit(MapError(message: 'Failed to update user: $e', previousState: currentMapState));
    }
  }

  // --- Device Event Handlers ---

  Future<void> _onGetUserDevices(GetUserTraccarDevices event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(TraccarDevicesLoading(previousState: currentMapState));
    try {
      _devices = await Traccar.getDevices() ?? [];
      emit(TraccarDevicesLoaded(previousState: currentMapState, devices: _devices));
    } catch (e) {
      emit(MapError(message: "Error fetching Traccar devices: ${e.toString()}", previousState: currentMapState));
    }
  }

  void _onTraccarDeviceSelected(TraccarDeviceSelected event, Emitter<MapState> emit) {
    final currentLoadedState = _getLoadedState();
    if (currentLoadedState.selectedDeviceId == event.deviceId) return;

    if (event.deviceId == null) {
      emit(currentLoadedState.copyWith(
        selectedDeviceId: null,
        traccarDeviceLastPosition: null,
      ));
    } else {
      emit(currentLoadedState.copyWith(selectedDeviceId: event.deviceId));
      add(GetLastKnownLocationForDevice(event.deviceId!));
    }
  }

  Future<void> _onGetLastKnownLocationForDevice(GetLastKnownLocationForDevice event, Emitter<MapState> emit) async {
    final currentLoadedState = _getLoadedState();
    emit(PositionByIdLoading(previousState: currentLoadedState));
    try {
      // Use the cached device list
      final device = _devices.firstWhere((d) => d.id == event.deviceId);
      if (device.lastPositionId != null) {
        final positionModel = await Traccar.getPositionById(device.lastPositionId.toString());
        emit(PositionByIdLoaded(previousState: currentLoadedState, position: positionModel));
        // Also update the core state's last position for smooth UI transition
        if (positionModel != null) {
          emit(currentLoadedState.copyWith(traccarDeviceLastPosition: positionModel));
        }
      } else {
        emit(PositionByIdLoaded(previousState: currentLoadedState, position: null));
      }
    } catch (e) {
      emit(MapError(message: "Error fetching last known location: ${e.toString()}", previousState: currentLoadedState));
    }
  }

  Future<void> _onDeleteTraccarDevice(DeleteTraccarDevice event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(DeleteTraccarDeviceLoading(previousState: currentMapState));
    try {
      final success = await Traccar.deleteDevice(event.deviceId);
      if (success) {
        // Remove from cache and emit success. The UI can then choose to refetch.
        _devices.removeWhere((d) => d.id == event.deviceId);
      }
      emit(DeleteTraccarDeviceLoaded(previousState: currentMapState, success: success));
    } catch (e) {
      emit(MapError(message: 'Failed to delete device: $e', previousState: currentMapState));
    }
  }

  // --- Other Feature Handlers (New Implementations) ---

  Future<void> _onGetTraccarRouteReport(GetTraccarRouteReport event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(ReportLoading(previousState: currentMapState));
    try {
      final reports = await Traccar.getRoute(event.deviceId.toString(), event.from, event.to) ?? [];
      emit(RouteReportLoaded(previousState: currentMapState, reports: reports));
    } catch (e) {
      emit(MapError(message: 'Failed to fetch route report: $e', previousState: currentMapState));
    }
  }

  Future<void> _onGetTraccarGeofencesByUserId(GetTraccarGeofencesByUserId event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(GeofencesLoading(previousState: currentMapState));
    try {
      final geofences = await Traccar.getGeoFencesByUserID(event.userId) ?? [];
      emit(GeofencesLoaded(previousState: currentMapState, geofences: geofences));
    } catch(e) {
      emit(MapError(message: 'Failed to fetch geofences: $e', previousState: currentMapState));
    }
  }

  Future<void> _onGetTraccarEventsReport(GetTraccarEventsReport event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(ReportLoading(previousState: currentMapState));
    try {
      final reports = await Traccar.getEvents(event.deviceId, event.from, event.to) ?? [];
      emit(EventsReportLoaded(previousState: currentMapState, reports: reports));
    } catch (e) {
      emit(MapError(message: 'Failed to fetch events report: $e', previousState: currentMapState));
    }
  }

  Future<void> _onGetTraccarTripReport(GetTraccarTripReport event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(ReportLoading(previousState: currentMapState));
    try {
      final reports = await Traccar.getTrip(event.deviceId, event.from, event.to) ?? [];
      emit(TripReportLoaded(previousState: currentMapState, reports: reports));
    } catch (e) {
      emit(MapError(message: 'Failed to fetch trip report: $e', previousState: currentMapState));
    }
  }

  Future<void> _onGetTraccarStopsReport(GetTraccarStopsReport event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(ReportLoading(previousState: currentMapState));
    try {
      final reports = await Traccar.getStops(event.deviceId, event.from, event.to) ?? [];
      emit(StopsReportLoaded(previousState: currentMapState, reports: reports));
    } catch (e) {
      emit(MapError(message: 'Failed to fetch stops report: $e', previousState: currentMapState));
    }
  }

  Future<void> _onGetTraccarSummaryReport(GetTraccarSummaryReport event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(ReportLoading(previousState: currentMapState));
    try {
      final summary = await Traccar.getSummary(event.deviceId, event.from, event.to);
      emit(SummaryReportLoaded(previousState: currentMapState, summary: summary));
    } catch (e) {
      emit(MapError(message: 'Failed to fetch summary report: $e', previousState: currentMapState));
    }
  }

  Future<void> _onAddTraccarDevice(AddTraccarDevice event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(AddTraccarDeviceLoading(previousState: currentMapState));
    try {
      final result = await Traccar.addDevice(event.deviceJson);
      emit(AddTraccarDeviceLoaded(previousState: currentMapState, responseBody: result));
    } catch (e) {
      emit(MapError(message: 'Failed to add device: $e', previousState: currentMapState));
    }
  }

  // Stubs for all other event handlers...
  // TODO: Implement the logic for the remaining event handlers following the established pattern.

  Future<void> _onGetTraccarDeviceById(GetTraccarDeviceById event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onUpdateTraccarDevice(UpdateTraccarDevice event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onGetTraccarPositions(GetTraccarPositions event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onGetLatestTraccarPositions(GetLatestTraccarPositions event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onGetTraccarSendCommands(GetTraccarSendCommands event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(SendCommandsLoading(previousState: currentMapState));
    print('[MapBloc]   $currentMapState');
    try {
      final commands = await Traccar.getSendCommands(event.id) ?? [];
      print('[MapBloc]   $commands');

    }
    catch(e) {
      print("Error while fetching commands: $e");
      // Use a more specific error message.
      emit(MapError(message: 'Failed to load commands for device: $e', previousState: currentMapState));
    }
  }

  Future<void> _onSendTraccarCommand(SendTraccarCommand event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onAddTraccarPermission(AddTraccarPermission event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onDeleteTraccarPermission(DeleteTraccarPermission event, Emitter<MapState> emit) async { /* ... */ }

  Future<void> _onGetTraccarGeofencesByDeviceId(GetTraccarGeofencesByDeviceId event, Emitter<MapState> emit) async {

    final currentMapState = _getLoadedState();
    emit(GeofencesLoading(previousState: currentMapState));
    print('[Mapstate] $currentMapState');
    try {
      final geofences = await Traccar.getGeoFencesByDeviceID(event.deviceId.toString()) ?? [];
      // Emit the loaded geofences. If none are found, this will correctly emit an empty list.
      emit(GeofencesLoaded(previousState: currentMapState, geofences: geofences));
      emit(currentMapState);
    } catch(e) {
      print("Error while fetching Geofence: $e");
      // Use a more specific error message.
      emit(MapError(message: 'Failed to load geofences for device: $e', previousState: currentMapState));
    }
  }


  Future<void> _onAddTraccarGeofence(AddTraccarGeofence event, Emitter<MapState> emit,) async {
    final currentMapState = _getLoadedState();
    emit(AddTraccarGeofenceLoading(previousState: currentMapState));

    try {
      // Step 1: Create Geofence (without devicesIds)
      final geofenceBody = event.geofenceJson;
      final geofenceResponse = await Traccar.addGeofence(geofenceBody,event.deviceId);
      if (geofenceResponse == null) {
        emit(MapError(message: "Failed to create geofence", previousState: currentMapState));
        return;
      }
      final geofenceResponseBody = jsonDecode(geofenceResponse);
      print("[MapBloc]   Geofence created ${geofenceResponseBody['id']}");

      final geofenceId = geofenceResponseBody['id'];

      // Step 2: Add permission
      final permissionBody = GeofencePermModel();
      permissionBody.geofenceId = geofenceId;
      permissionBody.deviceId = int.parse(event.deviceId);


      var perm = json.encode(permissionBody);

      final permissionSuccess = await Traccar.addPermission(perm);
      if (!permissionSuccess) {
        emit(MapError(message: "Failed to assign device to geofence", previousState: currentMapState));
        return;
      }
      emit(AddTraccarGeofenceLoaded(previousState: currentMapState, responseBody: "Geofence added and linked"));
      add(GetTraccarGeofencesByDeviceId(int.parse(event.deviceId)));
     // await Future.delayed(const Duration(milliseconds: 300));
      emit(currentMapState);
      print("Finalllyyyyyy ");
    } catch (e) {
      emit(MapError(message: "Error adding geofence: $e", previousState: currentMapState));
    }
  }
  Future<void> _onUpdateTraccarGeofence(UpdateTraccarGeofence event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onDeleteTraccarGeofence(DeleteTraccarGeofence event, Emitter<MapState> emit) async {
    final currentMapState = _getLoadedState();
    emit(DeleteTraccarGeofenceLoading(previousState: currentMapState));
    print("[Map Bloc] On Delete Traccar GeoFence   $currentMapState");
    try {
      // The Traccar API expects an integer ID for deletion.
      final success = await Traccar.deleteGeofence(event.id);
      emit(DeleteTraccarGeofenceLoaded(previousState: currentMapState, success: success));
      emit(currentMapState);

    } catch (e) {
      emit(MapError(message: "Failed to delete geofence: $e", previousState: currentMapState));
    }
  }
  Future<void> _onGetTraccarNotificationTypes(
      GetTraccarNotificationTypes event,
      Emitter<MapState> emit,
      ) async {
    final currentState = _getLoadedState();
    emit(NotificationTypesLoading(previousState: currentState));

    try {
      final types = await Traccar.getNotificationTypes();

      if (types != null && types.isNotEmpty) {
        emit(NotificationTypesLoaded(
          previousState: currentState,
          notificationTypes: types,
        ));
      } else {
        emit(MapError(
          message: 'No notification types found.',
          previousState: currentState,
        ));
      }
    } catch (e) {
      emit(MapError(
        message: 'Failed to load notification types: $e',
        previousState: currentState,
      ));
    }
  }

  Future<void> _onGetTraccarNotifications(GetTraccarNotifications event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onAddTraccarNotification(AddTraccarNotification event, Emitter<MapState> emit) async { /* ... */ }
  Future<void> _onDeleteTraccarNotification(DeleteTraccarNotification event, Emitter<MapState> emit) async { /* ... */ }

  // --- Helper & boilerplate methods ---

  Future<bool> _checkLocationPermission(Emitter<MapState> emit) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(const MapError(message: "Location permissions denied."));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      emit(const MapError(message: "Location permissions permanently denied."));
      return false;
    }
    return true;
  }

  Future<void> _onStartLocationTracking(StartLocationTracking event, Emitter<MapState> emit) async {
    if (_positionStream != null) return;
    if (await _checkLocationPermission(emit)) {
      try {
        const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10);
        _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
              (Position position) => add(LocationUpdated(position)),
          onError: (e) => add(LocationTrackingError(e.toString())),
        );
      } catch (e) {
        emit(MapError(message: e.toString(), previousState: _getLoadedState()));
      }
    }
  }

  void _onLocationTrackingError(LocationTrackingError event, Emitter<MapState> emit) {
    emit(MapError(message: event.errorMessage, previousState: _getLoadedState()));
  }

  Future<void> _onStopLocationTracking(StopLocationTracking event, Emitter<MapState> emit) async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _onStartTraccarWebSocket(StartTraccarWebSocket event, Emitter<MapState> emit) async {
    if (_webSocketSubscription != null) return;
    try {
      final stream = await Traccar.connectWebSocket();
      if (stream == null) {
        emit(MapError(message: "WebSocket stream is null.", previousState: _getLoadedState()));
        return;
      }
      _webSocketSubscription = stream.listen(
            (data) => add(TraccarDataReceived(data)),
        onError: (error) => emit(MapError(message: "WebSocket Error: $error", previousState: _getLoadedState())),
        onDone: () => _webSocketSubscription = null,
      );
    } catch (e) {
      emit(MapError(message: "Failed to connect to WebSocket: $e", previousState: _getLoadedState()));
    }
  }

  Future<void> _onStopTraccarWebSocket(StopTraccarWebSocket event, Emitter<MapState> emit) async {
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    Traccar.disconnectWebSocket();
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    _webSocketSubscription?.cancel();
    Traccar.disconnectWebSocket();
    return super.close();
  }
}