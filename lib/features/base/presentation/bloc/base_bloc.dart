import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'base_event.dart';
part 'base_state.dart';

class BaseBloc extends Bloc<BaseEvent, BaseState> {
  BaseBloc() : super(BaseState()) {
    on<TabIndexChanged>(_onTabIndexChanged);
  }

  FutureOr<void> _onTabIndexChanged(
    TabIndexChanged event,
    Emitter<BaseState> emit,
  ) {
    print("Tab Index changed");
    emit(state.copyWith(tabIndex: event.tabIndex));
  }
}
