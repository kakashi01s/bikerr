part of 'presentation_bloc.dart';

sealed class PresentationBlocState extends Equatable {
  const PresentationBlocState();

  @override
  List<Object> get props => [];
}

final class PresentationBlocInitial extends PresentationBlocState {}
