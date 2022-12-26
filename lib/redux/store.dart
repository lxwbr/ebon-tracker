import 'package:ebon_tracker/redux/attachments/attachments_actions.dart';
import 'package:ebon_tracker/redux/categories/categories_actions.dart';
import 'package:ebon_tracker/redux/categories/categories_state.dart';
import 'package:ebon_tracker/redux/main/main_actions.dart';
import 'package:ebon_tracker/redux/main/main_reducer.dart';
import 'package:ebon_tracker/redux/main/main_state.dart';
import 'package:ebon_tracker/redux/user/user_state.dart';
import 'package:meta/meta.dart';
import 'package:redux/redux.dart';

import 'attachments/attachments_reducer.dart';
import 'attachments/attachments_state.dart';
import 'categories/categories_reducer.dart';
import 'user/user_actions.dart';
import 'user/user_reducer.dart';

AppState appReducer(AppState state, dynamic action) {
  if (action is SetUserAccountStateAction) {
    final nextPostsState = userReducer(state.userState, action);
    return state.copyWith(
        mainState: state.mainState,
        userState: nextPostsState,
        attachmentsState: state.attachmentsState,
        categoriesState: state.categoriesState);
  }

  if (action is SetAttachmentsStateAction) {
    final nextPostsState = attachmentsReducer(state.attachmentsState, action);
    return state.copyWith(
        mainState: state.mainState,
        attachmentsState: nextPostsState,
        userState: state.userState,
        categoriesState: state.categoriesState);
  }

  if (action is SetMainStateAction) {
    final nextMainState = mainReducer(state.mainState, action);
    return state.copyWith(
        mainState: nextMainState,
        userState: state.userState,
        attachmentsState: state.attachmentsState,
        categoriesState: state.categoriesState);
  }

  if (action is CategoriesStateAction) {
    final nextMainState = categoriesReducer(state.categoriesState, action);
    return state.copyWith(
        mainState: state.mainState,
        userState: state.userState,
        attachmentsState: state.attachmentsState,
        categoriesState: nextMainState);
  }

  return state;
}

@immutable
class AppState {
  final CategoriesState categoriesState;
  final UserState userState;
  final AttachmentsState attachmentsState;
  final MainState mainState;

  const AppState(
      {required this.userState,
      required this.attachmentsState,
      required this.mainState,
      required this.categoriesState});

  AppState copyWith(
      {required MainState mainState,
      required UserState userState,
      required AttachmentsState attachmentsState,
      required CategoriesState categoriesState}) {
    return AppState(
        mainState: mainState,
        userState: userState,
        attachmentsState: attachmentsState,
        categoriesState: categoriesState);
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
    final mainStateInitial = MainState.initial();
    final categoriesInitial = CategoriesState.initial();

    _store = Store<AppState>(
      appReducer,
      initialState: AppState(
          mainState: mainStateInitial,
          userState: userStateInitial,
          attachmentsState: attachmentsStateInitial,
          categoriesState: categoriesInitial),
    );
  }
}
