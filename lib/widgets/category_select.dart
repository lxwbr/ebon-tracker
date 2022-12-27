import 'package:ebon_tracker/redux/categories/categories_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../data/category.dart';
import '../redux/store.dart';
import 'category.dart';

class CategorySelectPage extends StatelessWidget {
  const CategorySelectPage(
      {super.key,
      required this.name,
      required this.categories,
      required this.category});
  final String name;
  final Category? category;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          children: categories
              .map((e) => ListTile(
                    title: Text(e.name),
                    onTap: () async {
                      print("update $name with category: $e");
                    },
                  ))
              .toList()),
    );
  }
}
