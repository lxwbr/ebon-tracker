import 'dart:convert';

import 'package:dartz/dartz.dart' hide State;
import 'package:ebon_tracker/application/reader.dart';
import 'package:ebon_tracker/redux/store.dart';
import 'package:ebon_tracker/redux/user/user_actions.dart';
import 'package:ebon_tracker/widgets/receipts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../application/database_service.dart';
import '../data/attachment.dart';
import '../data/receipt.dart';
import '../redux/attachments/attachments_actions.dart';
import '../redux/attachments/attachments_state.dart';
import 'errors.dart';
import 'expenses.dart';

DatabaseService _databaseService = DatabaseService();

class Main extends StatefulWidget {
  const Main({super.key, required this.account});
  final GoogleSignInAccount account;

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context, [bool mounted = true]) {
    List<Widget> screens = [
      ReceiptsPage(account: widget.account),
      const ExpensesPage()
    ];

    return StoreConnector<AppState, AttachmentsState>(
        distinct: true,
        converter: (store) => store.state.attachmentsState,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
                actions: [
                  IconButton(
                      onPressed: () async {
                        List<Either<FailedReceipt, Receipt>> result =
                            await insertReceipts(state.attachments);
                        List<FailedReceipt> errors = result.lefts();

                        if (errors.isNotEmpty) {
                          if (!mounted) return;
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ErrorsPage(errors: errors)));
                        }
                      },
                      icon: const Icon(Icons.scanner)),
                  IconButton(
                      onPressed: () async {
                        if (state.attachments.isNotEmpty) {
                          int latest = state.attachments
                              .reduce((value, element) =>
                                  element.timestamp > value.timestamp
                                      ? element
                                      : value)
                              .timestamp;

                          fetchAttachmentsAction(Redux.store, latest);
                        } else {
                          fetchAttachmentsAction(Redux.store, null);
                        }
                      },
                      icon: const Icon(Icons.refresh))
                ],
                bottom: (() {
                  if (state.loading) {
                    return const PreferredSize(
                        preferredSize: Size.fromHeight(6.0),
                        child: LinearProgressIndicator(
                          semanticsLabel: 'Linear progress indicator',
                        ));
                  }
                })()),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: ListTile(
                      leading: GoogleUserCircleAvatar(
                        identity: widget.account,
                      ),
                      title: Text(widget.account.displayName ?? ''),
                      subtitle: Text(widget.account.email),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Clear attachments table'),
                    onTap: () async {
                      await deleteAttachmentsAction(Redux.store);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Clear expenses table'),
                    onTap: () async {
                      await _databaseService.deleteExpenses();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () async {
                      signOutAction(Redux.store);
                    },
                  ),
                ],
              ),
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt),
                    label: 'Receipts',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.local_grocery_store),
                    label: 'Expenses',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.amber[800],
                onTap: _onItemTapped),
          );
        });
  }
}
