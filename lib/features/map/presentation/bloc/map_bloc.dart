import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';
import 'package:bikerr/features/map/domain/usecases/get_current_location_usecase.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final GetCurrentLocationUsecase getCurrentLocationUsecase;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<dynamic>? _webSocketSubscription;

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
  }

  // Helper to safely get the current MapLoaded state.
  // If the state is not MapLoaded, it returns an empty MapLoaded,
  // which implies a fallback scenario where data might be missing.
  MapLoaded _getLoadedState() {
    if (state is MapLoaded) {
      return state as MapLoaded;
    }
    print("MapBloc: _getLoadedState: State was not MapLoaded. Creating a new base MapLoaded.");
    return const MapLoaded();
  }

  Future<void> _onGetInitialLocation(
      GetInitialLocation event,
      Emitter<MapState> emit,
      ) async {
    // Only transition from MapInitial or MapError to MapLoading
    if (state is MapInitial || state is MapError) {
      emit(const MapLoading(message: "Initializing map and getting location..."));
    } else if (state is MapLoaded && (state as MapLoaded).currentDevicePosition != null && !event.fetchOnce) {
      // If already loaded and not forced to refetch, just return.
      print('MapBloc: _onGetInitialLocation: Position already loaded and not fetching once. Skipping.');
      return;
    }

    final hasPermission = await _checkLocationPermission(emit);
    if (!hasPermission) {
      print('MapBloc: _onGetInitialLocation: No permission, stopping.');
      // Emit MapError if permission is denied.
      if (state is! MapError) {
        emit(MapError(message: "Location permission denied. Map cannot load.", previousState: _getLoadedState()));
      }
      return;
    }

    try {
      final initialPositionResult = await getCurrentLocationUsecase.getLocation();
      initialPositionResult.fold(
            (error) {
          print('MapBloc: _onGetInitialLocation: Error fetching initial position: $error');
          // If already in MapLoaded state, use it as previous. Otherwise, use a default.
          emit(MapError(message: error, previousState: _getLoadedState()));
        },
            (position) {
          print('MapBloc: _onGetInitialLocation: Initial position received: ${position.latitude}, ${position.longitude}');
          // *** Crucial: Emit MapLoaded with currentDevicePosition first. ***
          // All subsequent operations will update *this* MapLoaded state.
          emit(MapLoaded(currentDevicePosition: position));

          // Now, dispatch the other events. They will operate on the already
          // established MapLoaded state.
          add(const StartLocationTracking());
          add(GetUserTraccarDevices());
          add(StartTraccarWebSocket());
        },
      );
    } catch (e) {
      print('MapBloc: _onGetInitialLocation: Unexpected error: $e');
      emit(MapError(message: e.toString(), previousState: _getLoadedState()));
    }
  }

  Future<void> _onGetLastKnownLocationForDevice(
      GetLastKnownLocationForDevice event,
      Emitter<MapState> emit,
      ) async {
    if (state is! MapLoaded) {
      print("[MapBloc] _onGetLastKnownLocationForDevice: Not in MapLoaded state. Skipping.");
      return;
    }
    final currentLoadedState = state as MapLoaded; // Guaranteed to be MapLoaded here

    try {
      final Device? device = currentLoadedState.traccarDevices.firstWhere(
            (d) => d.id == event.deviceId,
        orElse: () => null!,
      );

      if (device == null || device.lastPositionId == null) {
        print("[MapBloc] Device not found or lastPositionId is null for device ID: ${event.deviceId}.");
        return;
      }

      final PositionModel? positionModel = await Traccar.getPositionById(
        device.lastPositionId.toString(),
      );

      if (positionModel != null) {
        final coords = LatLng(positionModel.latitude!, positionModel.longitude!);
        final updatedLocations = Map<int, LatLng>.from(currentLoadedState.traccarDeviceLocations)
          ..[device.id!] = coords;

        print("[MapBloc] Updated Traccar device ${device.id} location from last known.");
        emit(currentLoadedState.copyWith(traccarDeviceLocations: updatedLocations));
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
    if (state is! MapLoaded) return; // Guard clause

    final currentLoadedState = state as MapLoaded;

    // If the selected ID is the same, do nothing.
    if (currentLoadedState.selectedDeviceId == event.deviceId) {
      print("[MapBloc] Device ${event.deviceId} is already selected. No change.");
      return;
    }

    if (event.deviceId == null) {
      // *** THIS IS THE FIX ***
      // Manually create the new state to ensure selectedDeviceId is set to null.
      // This bypasses the faulty copyWith logic for the nullable field.
      emit(MapLoaded(
        currentDevicePosition: currentLoadedState.currentDevicePosition,
        traccarDevices: currentLoadedState.traccarDevices,
        selectedDeviceId: null, // Explicitly set to null
        traccarDeviceLocations: const {}, // Clear Traccar locations as per your original logic
        latestWebSocketRawData: currentLoadedState.latestWebSocketRawData,
      ));
      print("[MapBloc] 'This Device' selected. State updated and Traccar markers cleared.");

    } else {
      // For non-null device IDs, the existing logic works fine.
      emit(currentLoadedState.copyWith(selectedDeviceId: event.deviceId));

      // If we don't have the location for this device, fetch it.
      if (!currentLoadedState.traccarDeviceLocations.containsKey(event.deviceId!)) {
        add(GetLastKnownLocationForDevice(event.deviceId!));
      }
    }
  }

  Future<void> _getUserDevices(GetUserTraccarDevices event, Emitter<MapState> emit) async {
    if (state is! MapLoaded) {
      print("[MapBloc] _getUserDevices: Not in MapLoaded state. Skipping device fetch for now.");
      return; // Cannot update if not in a loaded state.
    }
    final currentLoadedState = state as MapLoaded; // Guaranteed to be MapLoaded here

    try {
      final response = await Traccar.getDevices();
      print("traccar devices: $response");

      if (response != null) {
        emit(currentLoadedState.copyWith(traccarDevices: response));
      } else {
        emit(currentLoadedState.copyWith(traccarDevices: []));
      }
    } catch (e) {
      print("Error getting traccar devices: $e");
      emit(MapError(message: "Error fetching Traccar devices: ${e.toString()}", previousState: currentLoadedState));
    }
  }

  Future<bool> _checkLocationPermission(Emitter<MapState> emit) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        emit(MapError(message: "Location permissions denied. Please enable them in settings.", previousState: _getLoadedState()));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      emit(MapError(message: "Location permissions permanently denied. Please enable them in app settings.", previousState: _getLoadedState()));
      return false;
    }
    print("Location permissions granted.");
    return true;
  }

  Future<void> _startContinuousLocationUpdates() async {
    await _positionStream?.cancel();

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        add(LocationUpdated(position));
        print('MapBloc (Stream): Received new device position: ${position.latitude}, ${position.longitude}, Heading: ${position.heading}');
      },
      onError: (e) {
        print('MapBloc (Stream Error): Error receiving device location: $e');
        add(LocationTrackingError(e.toString()));
      },
      onDone: () {
        print('MapBloc (Stream Done): Device location stream closed. Attempting to restart.');
        _positionStream = null; // Clear to allow new subscription
        add(const StartLocationTracking()); // Simple retry
      },
    );
    print('MapBloc (Stream): Continuous location updates started successfully.');
  }

  void _onLocationTrackingError(LocationTrackingError event, Emitter<MapState> emit) {
    emit(MapError(message: event.errorMessage, previousState: _getLoadedState()));
  }

  Future<void> _onStartLocationTracking(
      StartLocationTracking event,
      Emitter<MapState> emit,
      ) async {
    if (_positionStream != null) {
      print('MapBloc: _onStartLocationTracking: Continuous location tracking already active. No action.');
      return;
    }

    final hasPermission = await _checkLocationPermission(emit);
    if (!hasPermission) {
      print('MapBloc: _onStartLocationTracking: No permission, cannot start tracking.');
      return;
    }

    try {
      print('MapBloc: _onStartLocationTracking: Setting up continuous location updates.');
      await _startContinuousLocationUpdates();
      // No explicit emit here, `LocationUpdated` event will trigger state changes
    } catch (e) {
      print('MapBloc: _onStartLocationTracking: Error starting continuous updates: $e');
      emit(MapError(message: e.toString(), previousState: _getLoadedState()));
    }
  }

  void _onLocationUpdated(LocationUpdated event, Emitter<MapState> emit) {
    if (state is! MapLoaded) {
      print("MapBloc: _onLocationUpdated: Not in MapLoaded state. Cannot update position.");
      return;
    }
    print('MapBloc: _onLocationUpdated: Emitting state with new position: ${event.position.latitude}, ${event.position.longitude}');
    emit((state as MapLoaded).copyWith(currentDevicePosition: event.position));
  }

  Future<void> _onStopLocationTracking(
      StopLocationTracking event,
      Emitter<MapState> emit,
      ) async {
    await _positionStream?.cancel();
    _positionStream = null;
    print("MapBloc: Continuous location tracking stopped.");
  }

  Future<void> _onStartTraccarWebSocket(
      StartTraccarWebSocket event,
      Emitter<MapState> emit,
      ) async {
    if (_webSocketSubscription != null) {
      print("Traccar WebSocket already active.");
      return;
    }

    if (state is! MapLoaded) {
      print("[MapBloc] _onStartTraccarWebSocket: Not in MapLoaded state. WebSocket will connect but state won't update immediately.");
      // This is a defensive print. It means WebSocket might connect but MapLoaded isn't primary.
    }
    final currentLoadedState = _getLoadedState(); // Get the current base.

    try {
      final stream = await Traccar.connectWebSocket();

      if (stream == null) {
        emit(MapError(message: "WebSocket stream is null — cannot connect.", previousState: currentLoadedState));
        print("Traccar WebSocket stream is null — cannot connect.");
        return;
      }

      _webSocketSubscription = stream.listen(
            (data) {
          add(TraccarDataReceived(data));
        },
        onError: (error) {
          print("Traccar WebSocket Error: $error");
          // Always use the current state as previous for errors.
          emit(MapError(message: "WebSocket Error: ${error.toString()}", previousState: _getLoadedState()));
        },
        onDone: () {
          print("WebSocket closed unexpectedly, attempting to reconnect...");
          _webSocketSubscription = null; // Clear to allow new subscription
          add(StartTraccarWebSocket()); // Attempt to reconnect
        },
        cancelOnError: true,
      );

      print("Traccar WebSocket Connected and Listening");
      // If we've successfully connected, and we are in a loading state,
      // transition to loaded if not already. If already loaded, just maintain.
      if (state is MapLoading || state is MapError) {
        emit(currentLoadedState.copyWith()); // Transition to loaded, preserving data.
      }
    } catch (e, stackTrace) {
      print("Error connecting to Traccar WebSocket: $e");
      print(stackTrace);
      emit(MapError(message: "Failed to connect to WebSocket: ${e.toString()}", previousState: currentLoadedState));
    }
  }

  Future<void> _onStopTraccarWebSocket(
      StopTraccarWebSocket event,
      Emitter<MapState> emit,
      ) async {
    await _webSocketSubscription?.cancel();
    _webSocketSubscription = null;
    Traccar.disconnectWebSocket();
    print("Traccar WebSocket Disconnected");
  }

  void _onTraccarDataReceived(TraccarDataReceived event, Emitter<MapState> emit) {
    if (state is! MapLoaded) {
      print("[Map Bloc] TraccarDataReceived: Not in MapLoaded state. Cannot process data.");
      return;
    }
    print("[Map Bloc] Traccar WebSocket Data Received RAW: ${event.data.runtimeType} - ${event.data.toString()}");

    final currentLoadedState = state as MapLoaded;

    Map<int, LatLng> newTraccarLocations = Map<int, LatLng>.from(currentLoadedState.traccarDeviceLocations);
    List<Device> newTraccarDevices = List<Device>.from(currentLoadedState.traccarDevices);
    bool hasUpdate = false;

    if (event.data is List) {
      final List<dynamic> dataList = event.data as List<dynamic>;
      for (var item in dataList) {
        if (item is PositionModel) {
          final positionModel = item;
          if (positionModel.deviceId != null && positionModel.latitude != null && positionModel.longitude != null) {
            newTraccarLocations[positionModel.deviceId!] = LatLng(positionModel.latitude!, positionModel.longitude!);
            print("[Map Bloc] Updating Traccar device ${positionModel.deviceId} to ${newTraccarLocations[positionModel.deviceId!]} from List<PositionModel>.");
            hasUpdate = true;
          }
        } else if (item is Device) {
          final Device updatedDevice = item;
          final int index = newTraccarDevices.indexWhere((d) => d.id == updatedDevice.id);

          if (index != -1) {
            newTraccarDevices[index] = updatedDevice;
          } else {
            newTraccarDevices.add(updatedDevice);
          }
          print("[Map Bloc] Updating Traccar device list due to Device object in list: ${updatedDevice.id}");
          hasUpdate = true;
        }
      }
    } else if (event.data is PositionModel) {
      final positionModel = event.data as PositionModel;
      if (positionModel.deviceId != null && positionModel.latitude != null && positionModel.longitude != null) {
        newTraccarLocations[positionModel.deviceId!] = LatLng(positionModel.latitude!, positionModel.longitude!);
        print("[Map Bloc] Updating Traccar device ${positionModel.deviceId} to ${newTraccarLocations[positionModel.deviceId!]} from single PositionModel.");
        hasUpdate = true;
      }
    } else if (event.data is Device) {
      final Device updatedDevice = event.data as Device;
      final int index = newTraccarDevices.indexWhere((d) => d.id == updatedDevice.id);

      if (index != -1) {
        newTraccarDevices[index] = updatedDevice;
      } else {
        newTraccarDevices.add(updatedDevice);
      }
      print("[Map Bloc] Updating Traccar device list due to single Device object received: ${updatedDevice.id}");
      hasUpdate = true;
    }

    if (hasUpdate) {
      emit(currentLoadedState.copyWith(
        traccarDeviceLocations: newTraccarLocations,
        traccarDevices: newTraccarDevices,
        latestWebSocketRawData: event.data,
      ));
    } else {
      print("[Map Bloc] Traccar WebSocket Data received but not a recognized position or device update (final fallback): ${event.data.runtimeType} - ${event.data}");
      emit(currentLoadedState.copyWith( // Still emit to update rawData
        latestWebSocketRawData: event.data,
      ));
    }
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    _webSocketSubscription?.cancel();
    Traccar.disconnectWebSocket();
    return super.close();
  }
}