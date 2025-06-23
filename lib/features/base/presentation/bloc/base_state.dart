part of 'base_bloc.dart';

class BaseState extends Equatable {
  final int tabIndex;
  const BaseState({this.tabIndex = 0});

  BaseState copyWith({int? tabIndex}) {
    return BaseState(tabIndex: tabIndex ?? this.tabIndex);
  }

  @override
  List<Object> get props => [tabIndex];
}
