import 'package:ebon_tracker/redux/user/user_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

import '../redux/store.dart';

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eBon Tracker'),
      ),
      body: ConstrainedBox(
          constraints: const BoxConstraints.expand(),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SignInButton(
                  Buttons.GoogleDark,
                  onPressed: () async {
                    signInAction(Redux.store);
                  },
                )
              ])),
    );
  }
}
