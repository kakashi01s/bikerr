import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';
import 'package:bikerr/features/map/domain/usecases/get_current_location_usecase.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final GetCurrentLocationUsecase getCurrentLocationUsecase;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<dynamic>? _webSocketSubscription;
  List<Device> _traccarDevices = [];

  MapBloc(this.getCurrentLocationUsecase) : super(const MapInitial()) {
    on<GetInitialLocation>(_onGetInitialLocation);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<LocationUpdated>(_onLocationUpdated);
    on<GetUserTraccarDevices>(_getUserDevices);
    on<StartTraccarWebSocket>(_onStartTraccarWebSocket);
    on<StopTraccarWebSocket>(_onStopTraccarWebSocket);
    on<TraccarDataReceived>(_onTraccarDataReceived);
    on<LocationTrackingError>(_onLocationTrackingError);
    on<TraccarDeviceSelected>(_onTraccarDeviceSelected);
    on<GetLastKnownLocationForDevice>(_onGetLastKnownLocationForDevice);
    on<DeleteDevice>(_onDeleteTraccarDevice);
  }

  MapLoaded _getLoadedState() {
    final s = state;
    if (s is MapLoaded) {
      return s;
    } else if (s is MapError) {
      return s.previousState ?? const MapLoaded();
    } else if (s is LoadingDevices) {
      return s.previousState ?? const MapLoaded();
    } else if (s is TraccarDevicesLoaded) { // <-- ADD THIS BLOCK
      return s.previousState ?? const MapLoaded();
    }
    print(
        "MapBloc: _getLoadedState: State was not MapLoaded. Creating a new base MapLoaded.");
    return const MapLoaded();
  }

  Future<void> _onGetInitialLocation(
      GetInitialLocation event,
      Emitter<MapState> emit,
      ) async {
    if (state is MapInitial || state is MapError) {
      emit(const MapLoading(message: "Initializing map and getting location..."));
    } else if (state is MapLoaded && (state as MapLoaded).currentDevicePosition != null && !event.fetchOnce) {
      return;
    }

    final hasPermission = await _checkLocationPermission(emit);
    if (!hasPermission) {
      if (state is! MapError) {
        emit(MapError(message: "Location permission denied. Map cannot load.", previousState: _getLoadedState()));
      }
      return;
    }

    try {
      final initialPositionResult = await getCurrentLocationUsecase.getLocation();
      initialPositionResult.fold(
            (error) {
          emit(MapError(message: error, previousState: _getLoadedState()));
        },
            (position) {
          emit(MapLoaded(currentDevicePosition: position));
          add(const StartLocationTracking());
          add(GetUserTraccarDevices());
          add(StartTraccarWebSocket());
        },
      );
    } catch (e) {
      emit(MapError(message: e.toString(), previousState: _getLoadedState()));
    }
  }

  Future<void> _onGetLastKnownLocationForDevice(
      GetLastKnownLocationForDevice event,
      Emitter<MapState> emit,
      ) async {
    final currentLoadedState = _getLoadedState();
    try {
      final Device? device = _traccarDevices.firstWhere(
            (d) => d.id == event.deviceId,
        orElse: () => null!,
      );

      if (device?.lastPositionId == null) {
        print("[MapBloc] Device or its lastPositionId is null for device ID: ${event.deviceId}.");
        return;
      }

      final PositionModel? positionModel = await Traccar.getPositionById(device!.lastPositionId.toString());

      if (positionModel != null) {
        print("[MapBloc] Updated Traccar device ${device.id} with its last known position.");
        emit(currentLoadedState.copyWith(traccarDeviceLastPosition: positionModel));
      } else {
        print("[MapBloc] PositionModel was null for device ${device.id}.");
      }
    } catch (e) {
      print("[MapBloc] Error fetching last known location for device ${event.deviceId}: $e");
      emit(MapError(message: "Error fetching last known location: ${e.toString()}", previousState: currentLoadedState));
    }
  }

  void _onTraccarDeviceSelected(
      TraccarDeviceSelected event,
      Emitter<MapState> emit,
      ) {
    final currentLoadedState = _getLoadedState();
    if (currentLoadedState.selectedDeviceId == event.deviceId) {
      return;
    }

    // When selecting 'This Device', explicitly set the Traccar position to null.
    if (event.deviceId == null) {
      emit(currentLoadedState.copyWith(
        selectedDeviceId: null,
        traccarDeviceLastPosition: null, // Explicitly clear last position
      ));
    } else {
      // For any other device, set the ID and fetch its location.
      emit(currentLoadedState.copyWith(selectedDeviceId: event.deviceId));
      add(GetLastKnownLocationForDevice(event.deviceId!));
    }
  }

  Future<void> _getUserDevices(
      GetUserTraccarDevices event, Emitter<MapState> emit) async {
    final loadedState = _getLoadedState();
    emit(LoadingDevices(previousState: loadedState));
    try {
      final response = await Traccar.getDevices();
      _traccarDevices = response ?? [];
      emit(TraccarDevicesLoaded(
          traccarDevices: _traccarDevices, previousState: loadedState));
    } catch (e) {
      emit(MapError(
          message: "Error fetching Traccar devices: ${e.toString()}",
          previousState: loadedState));
    }
  }

  Future<void> _onTraccarDataReceived(
      TraccarDataReceived event,
      Emitter<MapState> emit,
      ) async {
    final currentLoadedState = _getLoadedState();

    // Clone the current state
    final newPositions = Map<int, PositionModel>.from(currentLoadedState.traccarDevicePositions);
    final newDevices = List<Device>.from(_traccarDevices);

    bool hasDeviceUpdate = false;
    PositionModel? newLastPosition;

    void processPosition(PositionModel position) {
      final deviceId = position.deviceId;
      if (deviceId != null) {
        newPositions[deviceId] = position;

        if (deviceId == currentLoadedState.selectedDeviceId) {
          newLastPosition = position;
        }
      }
    }

    void processDevice(Device device) {
      final index = newDevices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        newDevices[index] = device;
      } else {
        newDevices.add(device);
      }
      hasDeviceUpdate = true;
    }

    final data = event.data;

    // Handle batch or single message
    if (data is List) {
      for (final item in data) {
        if (item is PositionModel) processPosition(item);
        if (item is Device) processDevice(item);
      }
    } else if (data is PositionModel) {
      processPosition(data);
    } else if (data is Device) {
      processDevice(data);
    }

    emit(currentLoadedState.copyWith(
      traccarDevicePositions: newPositions,
      traccarDeviceLastPosition: newLastPosition ?? currentLoadedState.traccarDeviceLastPosition,
      latestWebSocketRawData: data,
    ));

    if (hasDeviceUpdate) {
      _traccarDevices = newDevices;
      emit(TraccarDevicesLoaded(
          traccarDevices: _traccarDevices, previousState: currentLoadedState));
    }
  }


  Future<void> _onDeleteTraccarDevice(DeleteDevice event, Emitter<MapState> emit) async {
    final currentState = _getLoadedState();
    emit(LoadingDevices(previousState: currentState, message: "Deleting device..."));

    try {
      await Traccar.deleteDevice(event.deviceId);
      final updatedDevices = await Traccar.getDevices() ?? [];
      _traccarDevices = updatedDevices;
      emit(TraccarDevicesLoaded(traccarDevices: _traccarDevices));

      final newPositions = Map<int, PositionModel>.from(currentState.traccarDevicePositions)..remove(event.deviceId);
      PositionModel? newLastPosition = currentState.traccarDeviceLastPosition;
      int? newSelectedId = currentState.selectedDeviceId;

      // If the deleted device was selected, revert to "This Device"
      if (currentState.selectedDeviceId == event.deviceId) {
        newSelectedId = null;
        newLastPosition = null; // Clear the last position
      }

      emit(currentState.copyWith(
        selectedDeviceId: newSelectedId,
        traccarDevicePositions: newPositions,
        traccarDeviceLastPosition: newLastPosition,
      ));

    } catch (e) {
      emit(MapError(message: 'Failed to delete device: $e', previousState: currentState));
    }
  }

  // Other methods (_checkLocationPermission, _startContinuousLocationUpdates, etc.) remain unchanged
  Future<bool> _checkLocationPermission(Emitter<MapState> emit) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(MapError(message: "Location permissions denied.", previousState: _getLoadedState()));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      emit(MapError(message: "Location permissions permanently denied.", previousState: _getLoadedState()));
      return false;
    }
    return true;
  }

  Future<void> _startContinuousLocationUpdates() async {
    await _positionStream?.cancel();
    const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) => add(LocationUpdated(position)),
      onError: (e) => add(LocationTrackingError(e.toString())),
      onDone: () {
        _positionStream = null;
        add(const StartLocationTracking());
      },
    );
  }

  void _onLocationTrackingError(LocationTrackingError event, Emitter<MapState> emit) {
    emit(MapError(message: event.errorMessage, previousState: _getLoadedState()));
  }

  Future<void> _onStartLocationTracking(
      StartLocationTracking event,
      Emitter<MapState> emit,
      ) async {
    if (_positionStream != null) return;
    if (await _checkLocationPermission(emit)) {
      try {
        await _startContinuousLocationUpdates();
      } catch (e) {
        emit(MapError(message: e.toString(), previousState: _getLoadedState()));
      }
    }
  }

  void _onLocationUpdated(LocationUpdated event, Emitter<MapState> emit) {
    emit(_getLoadedState().copyWith(currentDevicePosition: event.position));
  }

  Future<void> _onStopLocationTracking(
      StopLocationTracking event,
      Emitter<MapState> emit,
      ) async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _onStartTraccarWebSocket(
      StartTraccarWebSocket event,
      Emitter<MapState> emit,
      ) async {
    if (_webSocketSubscription != null) return;
    final currentLoadedState = _getLoadedState();
    try {
      final stream = await Traccar.connectWebSocket();
      if (stream == null) {
        emit(MapError(message: "WebSocket stream is null.", previousState: currentLoadedState));
        return;
      }
      _webSocketSubscription = stream.listen(
            (data) => add(TraccarDataReceived(data)),
        onError: (error) => emit(MapError(message: "WebSocket Error: $error", previousState: _getLoadedState())),
        onDone: () {
          _webSocketSubscription = null;
          add(StartTraccarWebSocket());
        },
        cancelOnError: true,
      );
      if (state is! MapLoaded) {
        emit(currentLoadedState.copyWith());
      }
    } catch (e) {
      emit(MapError(message: "Failed to connect to WebSocket: $e", previousState: currentLoadedState));
    }
  }

  Future<void> _onStopTraccarWebSocket(
      StopTraccarWebSocket event,
      Emitter<MapState> emit,
      ) async {
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