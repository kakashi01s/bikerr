import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'presentation_event.dart';
part 'presentation_state.dart';

class PresentationBlocBloc
    extends Bloc<PresentationBlocEvent, PresentationBlocState> {
  PresentationBlocBloc() : super(PresentationBlocInitial()) {
    on<PresentationBlocEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
