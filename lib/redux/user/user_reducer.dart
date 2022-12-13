import 'package:ebon_tracker/redux/user/user_actions.dart';

import 'user_state.dart';

userReducer(UserState prevState, SetUserAccountStateAction action) {
  final payload = action.userState;
  return prevState.copyWith(
      account: payload.account, signingIn: payload.signingIn);
}
