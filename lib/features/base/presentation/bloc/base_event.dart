part of 'base_bloc.dart';

abstract class BaseEvent extends Equatable {
  const BaseEvent();

  @override
  List<Object> get props => [];
}

class TabIndexChanged extends BaseEvent {
  final int tabIndex;

  const TabIndexChanged({required this.tabIndex});

  @override
  // TODO: implement props
  List<Object> get props => [tabIndex];
}
