import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'redux/attachments/attachments_actions.dart';
import 'redux/store.dart';
import 'widgets/signin.dart';

void main() async {
  await Redux.init();

  runApp(
    MaterialApp(
        theme: ThemeData.dark(),
        home: StoreProvider<AppState>(
          store: Redux.store,
          child: StoreConnector<AppState, GoogleSignInAccount?>(
            distinct: true,
            converter: (store) => store.state.userState.account,
            builder: (context, account) {
              if (account != null) {
                dbListAttachmentsAction();
                return App(account: account);
              } else {
                return const SignIn();
              }
            },
          ),
        )),
  );
}
