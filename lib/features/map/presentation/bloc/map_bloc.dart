import 'dart:async';

import 'package:bikerr/features/map/domain/usecases/get_current_location_usecase.dart';
import 'package:bikerr/features/map/domain/usecases/traccar_use_case.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:traccar_gennissi/traccar_gennissi.dart';

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
  }

  Future<void> _getUserDevices(GetUserTraccarDevices event, Emitter<MapState> emit) async {
    emit(state.copyWith(postApiStatus: PostApiStatus.loading));
    final result = await traccarUseCase.getUserDevices() ?? [];
    print("[Map Bloc] User Devices Loaded ${result.toString()}");
    emit(state.copyWith(traccarDevices: result, postApiStatus: PostApiStatus.success));
  }

  Future<void> _startContinuousLocationUpdates(Emitter<MapState> emit) async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
      timeLimit: const Duration(seconds: 5),
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
        add(LocationUpdated(position));
      },
      onError: (e) {
        emit(
          state.copyWith(
            postApiStatus: PostApiStatus.error,
            errorMessage: e.toString(),
          ),
        );
      },
    );
  }

  Future<void> _onStartLocationTracking(
      StartLocationTracking event,
      Emitter<MapState> emit,
      ) async {
    if (state.postApiStatus == PostApiStatus.loading) {
      return;
    }

    try {
      await _startContinuousLocationUpdates(emit);
    } catch (e) {
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
    final fetchOnce = event.fetchOnce; // Assuming fetchOnce is a property of GetInitialLocation
    if (state.postApiStatus == PostApiStatus.loading) {
      return;
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
        await _startContinuousLocationUpdates(emit);
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

  // New: WebSocket event handlers
  Future<void> _onStartTraccarWebSocket(
      StartTraccarWebSocket event,
      Emitter<MapState> emit,
      ) async {
    try {
      // Ensure previous subscription is cancelled before starting a new one
      await _webSocketSubscription?.cancel();
      _webSocketSubscription = Traccar.connectWebSocket()?.listen(
            (data) {
          add(TraccarDataReceived(data));
        },
        onError: (error) {
          print("Traccar WebSocket Error: $error");
          emit(state.copyWith(postApiStatus: PostApiStatus.error, errorMessage: "WebSocket Error: $error"));
        },
        onDone: () {
          print("Traccar WebSocket Closed");
        },
      );
      print("Traccar WebSocket Connected and Listening");
    } catch (e) {
      print("Error connecting to Traccar WebSocket: $e");
      emit(state.copyWith(postApiStatus: PostApiStatus.error, errorMessage: "Failed to connect to WebSocket: $e"));
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