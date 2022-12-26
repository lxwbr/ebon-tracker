import 'package:ebon_tracker/redux/categories/categories_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../data/category.dart';
import '../redux/store.dart';
import 'category.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, CategoriesState>(
        distinct: true,
        converter: (store) => store.state.categoriesState,
        builder: (context, state) {
          return Scaffold(
            body: Column(
                children: state.categories
                    .map((e) => ListTile(
                          title: Text(e.name),
                          onTap: () async {},
                        ))
                    .toList()),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CategoryPage(
                              categories: state.categories,
                            )));
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            ),
          );
        });
  }
}
