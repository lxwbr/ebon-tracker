import 'package:ebon_tracker/redux/attachments/attachments_actions.dart';
import 'package:ebon_tracker/redux/user/user_state.dart';
import 'package:meta/meta.dart';
import 'package:redux/redux.dart';

import 'attachments/attachments_reducer.dart';
import 'attachments/attachments_state.dart';
import 'user/user_actions.dart';
import 'user/user_reducer.dart';

AppState appReducer(AppState state, dynamic action) {
  if (action is SetUserAccountStateAction) {
    final nextPostsState = userReducer(state.userState, action);
    return state.copyWith(
        userState: nextPostsState, attachmentsState: state.attachmentsState);
  }

  if (action is SetAttachmentsStateAction) {
    final nextPostsState = attachmentsReducer(state.attachmentsState, action);
    return state.copyWith(
        attachmentsState: nextPostsState, userState: state.userState);
  }

  return state;
}

@immutable
class AppState {
  final UserState userState;
  final AttachmentsState attachmentsState;

  const AppState({required this.userState, required this.attachmentsState});

  AppState copyWith(
      {required UserState userState,
      required AttachmentsState attachmentsState}) {
    return AppState(
      userState: userState,
      attachmentsState: attachmentsState,
    );
  }
}

class Redux {
  static Store<AppState>? _store;

  static Store<AppState> get store {
    if (_store == null) {
      throw Exception("store is not initialized");
    } else {
      return _store!;
    }
  }

  static Future<void> init() async {
    final userStateInitial = UserState.initial();
    final attachmentsStateInitial = AttachmentsState.initial();

    _store = Store<AppState>(
      appReducer,
      initialState: AppState(
          userState: userStateInitial,
          attachmentsState: attachmentsStateInitial),
    );
  }
}
