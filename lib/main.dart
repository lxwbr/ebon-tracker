import 'package:ebon_tracker/widgets/receipts.dart';
import 'package:ebon_tracker/widgets/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'redux/attachments/attachments_actions.dart';
import 'redux/store.dart';
import 'widgets/signin.dart';

GoogleSignIn _googleSignIn =
    GoogleSignIn(scopes: ["https://www.googleapis.com/auth/gmail.readonly"]);

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
                dbListAttachmentsAction(Redux.store);
                return Main(account: account);
              } else {
                return SignIn();
              }
            },
          ),
        )),
  );
}
