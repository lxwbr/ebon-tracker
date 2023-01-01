import 'package:ebon_tracker/application/database_service.dart';
import 'package:ebon_tracker/application/export.dart';
import 'package:ebon_tracker/data/category.dart';
import 'package:ebon_tracker/redux/categories/categories_actions.dart';
import 'package:ebon_tracker/redux/store.dart';
import 'package:ebon_tracker/redux/user/user_actions.dart';
import 'package:ebon_tracker/widgets/categories.dart';
import 'package:ebon_tracker/widgets/expenses.dart';
import 'package:ebon_tracker/widgets/expenses_export.dart';
import 'package:ebon_tracker/widgets/receipts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../redux/attachments/attachments_actions.dart';

class App extends StatefulWidget {
  const App({super.key, required this.account});
  final GoogleSignInAccount account;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    CategoriesDb.all().then((value) {
      setCategories(value);
    });
  }

  @override
  Widget build(BuildContext context, [bool mounted = true]) {
    List<Widget> screens = [
      ReceiptsPage(account: widget.account),
      const ExpensesPage(),
      const CategoriesPage()
    ];

    return StoreConnector<AppState, AppState>(
        distinct: true,
        converter: (store) => store.state,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(bottom: (() {
              return PreferredSize(
                  preferredSize: const Size.fromHeight(6.0),
                  child: LinearProgressIndicator(
                    value: state.mainState.loading == double.infinity
                        ? null
                        : state.mainState.loading,
                  ));
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
                      await deleteExpensesAction();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Clear categories table'),
                    onTap: () async {
                      await CategoriesDb.purge();
                      setCategories([]);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.import_export),
                    title: const Text('Export expenses'),
                    onTap: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ExportExpensesPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.import_export),
                    title: const Text('Export categories'),
                    onTap: () async {
                      await exportCategories(state.categoriesState.categories);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.import_export),
                    title: const Text('Export products'),
                    onTap: () async {
                      await exportProducts();
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
                  BottomNavigationBarItem(
                    icon: Icon(Icons.label),
                    label: 'Categories',
                  ),
                ],
                currentIndex: _selectedIndex,
                selectedItemColor: Colors.amber[800],
                onTap: _onItemTapped),
          );
        });
  }
}
