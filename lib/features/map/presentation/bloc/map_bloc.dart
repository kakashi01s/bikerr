import 'dart:async';

import 'package:bikerr/features/map/domain/usecases/get_current_location_usecase.dart';
import 'package:bikerr/features/map/domain/usecases/traccar_use_case.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

import '../../../../services/session/session_manager.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final GetCurrentLocationUsecase getCurrentLocationUsecase;
  final TraccarUseCase traccarUseCase;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<dynamic>? _webSocketSubscription; // New: WebSocket subscription

  MapBloc({required this.getCurrentLocationUsecase, required this.traccarUseCase}) : super(const MapState()) {
    on<GetInitialLocation>(_onGetInitialLocation);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<LocationUpdated>(_onLocationUpdated);
    on<GetUserTraccarDevices>(_getUserDevices);
    on<StartTraccarWebSocket>(_onStartTraccarWebSocket); // New: Handle WebSocket start
    on<StopTraccarWebSocket>(_onStopTraccarWebSocket);   // New: Handle WebSocket stop
    on<TraccarDataReceived>(_onTraccarDataReceived);     // New: Handle WebSocket data
    on<LocationTrackingError>(_onLocationTrackingError);
    on<TraccarDeviceSelected>(_onTraccarDeviceSelected);
    on<GetLastKnownLocationForDevice>(_onGetLastKnownLocationForDevice);
  }

  Future<void> _onGetLastKnownLocationForDevice(
      GetLastKnownLocationForDevice event,
      Emitter<MapState> emit,
      ) async {

    try {
      Device? device;
      try {
        device = state.traccarDevices?.firstWhere((d) => d.id == event.deviceId);
      } catch (_) {
        device = null;
      }
      print("Device ${device?.id}     Device from state ${event.deviceId}");
      if (device == null || device.lastPositionId == null) {
        print("[MapBloc] Device not found or lastPositionId is null.");
        return;
      }
      print("Device Id ${device.id}");
      print("PositionId Id ${device.lastPositionId}");
      final positionModel = await Traccar.getPositionById(
        device.lastPositionId.toString(),
      );

      if (positionModel != null) {
        final coords = LatLng(positionModel.latitude!, positionModel.longitude!);

        final updatedLocations = Map<int, LatLng>.from(state.traccarDeviceLocations)
          ..[device.id!] = coords;
        print("[MapBloc] Updated Positions ${updatedLocations}");
        emit(state.copyWith(traccarDeviceLocations: updatedLocations));
      } else {
        print("[MapBloc] PositionModel was null.");
      }
    } catch (e) {
      print("[MapBloc] Error fetching last known location: $e");
    }
  }



  void _onTraccarDeviceSelected(
      TraccarDeviceSelected event,
      Emitter<MapState> emit,
      ) {
    emit(state.copyWith(selectedDeviceId: event.deviceId));
  }
  Future<void> _getUserDevices(GetUserTraccarDevices event, Emitter<MapState> emit) async {
    print("Getting traccar devices");
    emit(state.copyWith(postApiStatus: PostApiStatus.loading, errorMessage: null)); // Clear previous error message

    try {
      final response = await traccarUseCase.getUserDevices();
      print("traccar devices: $response");

      if (response != null && response.isNotEmpty) {
        emit(state.copyWith(postApiStatus: PostApiStatus.success, traccarDevices: response));
      } else {
        // IMPORTANT CHANGE: Emit success with an empty list if no devices are found.
        // This ensures the dropdown still builds with "This Device" option.
        emit(state.copyWith(postApiStatus: PostApiStatus.success, traccarDevices: []));
      }
    } catch (e) {
      print("Error getting traccar devices: $e");
      emit(state.copyWith(postApiStatus: PostApiStatus.error, errorMessage: e.toString()));
    }
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle this case (e.g., show a dialog to the user)
        print("Location permissions are denied.");
        // You might want to emit an error state here
        add(LocationTrackingError("Location permissions denied. Please enable them in settings."));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle this case (e.g., guide user to settings)
      print("Location permissions are permanently denied.");
      // You might want to emit an error state here
      add(LocationTrackingError("Location permissions permanently denied. Please enable them in app settings."));
      return false;
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      add(GetInitialLocation(fetchOnce: true));
    }
    // Permissions are granted, proceed
    print("Location permissions granted.");
    return true;
  }


  Future<void> _startContinuousLocationUpdates() async { // Removed Emitter emit from here
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: const Duration(seconds: 15),
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        add(LocationUpdated(position));
      },
      onError: (e) {
        // Instead of emitting directly, add a new event to the bloc
        add(LocationTrackingError(e.toString()));
      },
    );
  }

  // New Event Handler for Location Tracking Errors
  void _onLocationTrackingError(LocationTrackingError event, Emitter<MapState> emit) {
    emit(
      state.copyWith(
        postApiStatus: PostApiStatus.error,
        errorMessage: event.errorMessage,
      ),
    );
  }

  Future<void> _onStartLocationTracking(
      StartLocationTracking event,
      Emitter<MapState> emit,
      ) async {
    if (state.postApiStatus == PostApiStatus.loading) {
      return;
    }

    final hasPermission = await _checkLocationPermission(); // Check permissions first
    if (!hasPermission) {
      return; // Stop if permissions are not granted
    }

    try {
      // You don't need to await _startContinuousLocationUpdates because
      // it sets up a stream listener that runs independently.
      // The initial emission might be for 'loading' or 'success' if needed immediately.
      await _startContinuousLocationUpdates(); // Call the stream setup
      emit(state.copyWith(postApiStatus: PostApiStatus.success)); // Or an appropriate initial state
    } catch (e) {
      // This catch block would only catch errors from _startContinuousLocationUpdates itself,
      // not from the stream's onError.
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetInitialLocation(
      GetInitialLocation event,
      Emitter<MapState> emit,
      ) async {
    final fetchOnce = event.fetchOnce;
    final isPositionLoaded = state.position != null;
    final isTracking = _positionStream != null;

    if (isPositionLoaded && isTracking) {
      return; // Already tracking, no need to reinitialize
    }
    final hasPermission = await _checkLocationPermission(); // Check permissions first
    if (!hasPermission) {
      return; // Stop if permissions are not granted
    }
    try {
      if (fetchOnce) {
        final initialPositionResult =
        await getCurrentLocationUsecase.getLocation();
        initialPositionResult.fold(
              (error) => emit(
            state.copyWith(
              postApiStatus: PostApiStatus.error,
              errorMessage: error,
            ),
          ),
              (position) => emit(
            state.copyWith(
              position: position,
              postApiStatus: PostApiStatus.success,
            ),
          ),
        );
        // Start continuous tracking after initial fetch
        add(StartLocationTracking());
      } else {
        await _startContinuousLocationUpdates(); // Call the stream setup
        // If you need to emit a state right after starting continuous updates, do it here
        emit(state.copyWith(postApiStatus: PostApiStatus.success));
      }
    } catch (e) {
      emit(
        state.copyWith(
          postApiStatus: PostApiStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onLocationUpdated(LocationUpdated event, Emitter<MapState> emit) {
    emit(
      state.copyWith(
        position: event.position,
        postApiStatus: PostApiStatus.success,
      ),
    );
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
    try {
      // Cancel any previous subscription before starting a new one
      await _webSocketSubscription?.cancel();

      final stream = await Traccar.connectWebSocket();

      if (stream == null) {
        emit(state.copyWith(
          postApiStatus: PostApiStatus.error,
          errorMessage: "WebSocket stream is null",
        ));
        print("Traccar WebSocket stream is null — cannot connect.");
        return;
      }

      _webSocketSubscription = stream.listen(
            (data) {
          add(TraccarDataReceived(data)); // Dispatch event for each incoming message
        },
        onError: (error) {
          print("Traccar WebSocket Error: $error");
          emit(state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: "WebSocket Error: $error",
          ));
        },
        onDone: () {
          print("WebSocket closed unexpectedly, attempting to reconnect...");
          add(StartTraccarWebSocket()); // Simple retry
        },
        cancelOnError: true, // Ensures stream is closed on error
      );

      print("Traccar WebSocket Connected and Listening");
    } catch (e, stackTrace) {
      print("Error connecting to Traccar WebSocket: $e");
      print(stackTrace);
      emit(state.copyWith(
        postApiStatus: PostApiStatus.error,
        errorMessage: "Failed to connect to WebSocket: $e",
      ));
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

  void _onTraccarDataReceived(
      TraccarDataReceived event,
      Emitter<MapState> emit,
      ) {
    // You can process the 'data' here and update the state accordingly.
    // For example, if 'data' is a Device, you can add it to a list of devices in the state.
    // The type of 'data' depends on what Traccar's WebSocket sends.
    print("[Map Bloc] Traccar WebSocket Data Received: ${event.data.toString()}");

    if (event.data is Map && event.data['type'] == 'position') {
      final int deviceId = event.data['deviceId'];
      final double lat = event.data['latitude'];
      final double lng = event.data['longitude'];

      final updatedMap = Map<int, LatLng>.from(state.traccarDeviceLocations);
      updatedMap[deviceId] = LatLng(lat, lng);

      emit(state.copyWith(traccarDeviceLocations: updatedMap));
    }

    emit(state.copyWith(webSocketData: event.data));
  }

  @override
  Future<void> close() {
    _positionStream?.cancel();
    _webSocketSubscription?.cancel(); // New: Cancel WebSocket subscription
    Traccar.disconnectWebSocket(); // New: Ensure WebSocket is disconnected
    return super.close();
  }
}