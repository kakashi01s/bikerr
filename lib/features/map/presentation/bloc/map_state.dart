part of 'map_bloc.dart';

class MapState extends Equatable {
  final Position? position;
  final PostApiStatus postApiStatus;
  final String? errorMessage;

  const MapState({
    this.position,
    this.postApiStatus = PostApiStatus.initial,
    this.errorMessage,
  });

  MapState copyWith({
    Position? position,
    PostApiStatus? postApiStatus,
    String? errorMessage,
  }) {
    return MapState(
      position: position ?? this.position,
      postApiStatus: postApiStatus ?? this.postApiStatus,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [position, postApiStatus, errorMessage];
}
