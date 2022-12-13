import 'package:google_sign_in/google_sign_in.dart';
import 'package:redux/redux.dart';
import 'package:meta/meta.dart';

import '../store.dart';
import 'user_state.dart';

GoogleSignIn _googleSignIn =
    GoogleSignIn(scopes: ["https://www.googleapis.com/auth/gmail.readonly"]);

@immutable
class SetUserAccountStateAction {
  final UserState userState;

  const SetUserAccountStateAction(this.userState);
}

Future<void> signInAction(Store<AppState> store) async {
  store.dispatch(const SetUserAccountStateAction(UserState(signingIn: true)));

  try {
    GoogleSignInAccount? account =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();

    store.dispatch(
      SetUserAccountStateAction(
        UserState(account: account),
      ),
    );
  } catch (error) {
    store
        .dispatch(const SetUserAccountStateAction(UserState(signingIn: false)));
  }
}

Future<void> signOutAction(Store<AppState> store) async {
  store.dispatch(const SetUserAccountStateAction(UserState(signingIn: true)));

  try {
    GoogleSignInAccount? account = await _googleSignIn.signOut();

    store.dispatch(
      SetUserAccountStateAction(
        UserState(account: account),
      ),
    );
  } catch (error) {
    store
        .dispatch(const SetUserAccountStateAction(UserState(signingIn: false)));
  }
}
