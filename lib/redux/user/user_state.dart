import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart';

@immutable
class UserState {
  final GoogleSignInAccount? account;
  final bool signingIn;

  const UserState({this.account, this.signingIn = false});

  factory UserState.initial() => const UserState();

  UserState copyWith({GoogleSignInAccount? account, required bool signingIn}) {
    return UserState(account: account, signingIn: signingIn);
  }
}
