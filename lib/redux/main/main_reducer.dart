import 'main_actions.dart';
import 'main_state.dart';

mainReducer(MainState prevState, SetMainStateAction action) {
  final payload = action.mainState;
  return prevState.copyWith(loading: payload.loading);
}
