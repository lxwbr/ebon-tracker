import 'package:ebon_tracker/redux/categories/categories_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../data/category.dart';
import '../redux/store.dart';
import 'category.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Widget _categoryTile(Category category, int level, BuildContext context,
      List<Category> categories) {
    return ListTile(
        title: Text("${List.filled(4 * level, " ").join()}${category.name}"),
        onLongPress: () {
          _pushCategoryPage(context, categories, category);
        });
  }

  Widget _subCategories(BuildContext context, List<Category> categories,
      Category category, int level) {
    Iterable<Category> subCategories =
        categories.where((subcategory) => subcategory.parentId == category.id);

    if (subCategories.isNotEmpty) {
      return ExpansionTile(
        title: _categoryTile(category, level, context, categories),
        children: subCategories
            .map((subcategory) =>
                _subCategories(context, categories, subcategory, level + 1))
            .toList(),
      );
    } else {
      return _categoryTile(category, level + 1, context, categories);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, CategoriesState>(
        distinct: true,
        converter: (store) => store.state.categoriesState,
        builder: (context, state) {
          return Scaffold(
            body: Column(
                children: state.categories
                    .where((category) => category.parentId == null)
                    .map((category) =>
                        _subCategories(context, state.categories, category, 0))
                    .toList()),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _pushCategoryPage(context, state.categories),
              backgroundColor: Colors.green,
              child: const Icon(Icons.add),
            ),
          );
        });
  }

  void _pushCategoryPage(BuildContext context, List<Category> categories,
      [Category? selected]) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                CategoryPage(categories: categories, selected: selected)));
  }
}
