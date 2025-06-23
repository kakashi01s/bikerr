part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class GetInitialLocation extends MapEvent {}

class StartLocationTracking extends MapEvent {}

class StopLocationTracking extends MapEvent {}

class LocationUpdated extends MapEvent {
  final Position position;

  const LocationUpdated(this.position);

  @override
  List<Object?> get props => [position];
}
