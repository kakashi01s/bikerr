import 'dart:async';

import 'package:bikerr/features/map/domain/usecases/get_current_location_usecase.dart';
import 'package:bikerr/utils/enums/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final GetCurrentLocationUsecase getCurrentLocationUsecase;
  StreamSubscription<Position>? _positionStream;

  MapBloc({required this.getCurrentLocationUsecase}) : super(const MapState()) {
    on<GetInitialLocation>(_onGetInitialLocation);
    on<StartLocationTracking>(_onStartLocationTracking);
    on<StopLocationTracking>(_onStopLocationTracking);
    on<LocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onGetInitialLocation(
    GetInitialLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(postApiStatus: PostApiStatus.loading));
    await _handleLocationFetching(emit, fetchOnce: true);
  }

  Future<void> _onStartLocationTracking(
    StartLocationTracking event,
    Emitter<MapState> emit,
  ) async {
    await _startContinuousLocationUpdates(emit);
  }

  Future<void> _startContinuousLocationUpdates(Emitter<MapState> emit) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.locationServiceDisabled),
      );
      return;
    }

    final permission = await getCurrentLocationUsecase.checkPermission();
    if (permission == LocationPermission.denied) {
      final granted = await getCurrentLocationUsecase.requestPermission();
      if (!granted) {
        emit(state.copyWith(postApiStatus: PostApiStatus.permissionDenied));
        return;
      }
    } else if (permission == LocationPermission.deniedForever) {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.permissionDeniedForever),
      );
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(
      (Position position) {
        // print(
        //   "Location Received in BLoC: ${position.latitude}, ${position.longitude}",
        // );
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

  Future<void> _handleLocationFetching(
    Emitter<MapState> emit, {
    bool fetchOnce = false,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.locationServiceDisabled),
      );
      return;
    }

    final permission = await getCurrentLocationUsecase.checkPermission();
    if (permission == LocationPermission.denied) {
      final granted = await getCurrentLocationUsecase.requestPermission();
      if (!granted) {
        emit(state.copyWith(postApiStatus: PostApiStatus.permissionDenied));
        return;
      }
    } else if (permission == LocationPermission.deniedForever) {
      emit(
        state.copyWith(postApiStatus: PostApiStatus.permissionDeniedForever),
      );
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
    // print(
    //   "LocationUpdated Event Received in BLoC: ${event.position.latitude}, ${event.position.longitude}",
    // );
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

  @override
  Future<void> close() {
    _positionStream?.cancel();
    return super.close();
  }
}
