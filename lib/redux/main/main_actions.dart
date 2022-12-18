import 'package:redux/redux.dart';
import '../store.dart';
import 'main_state.dart';

class SetMainStateAction {
  final MainState mainState;

  const SetMainStateAction(this.mainState);
}

void loadingAction([double loading = double.infinity]) {
  Redux.store.dispatch(SetMainStateAction(MainState(loading: loading)));
}

void loadedAction() {
  Redux.store.dispatch(const SetMainStateAction(MainState(loading: 0.0)));
}
