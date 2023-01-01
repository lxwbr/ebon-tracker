import 'package:ebon_tracker/redux/categories/categories_actions.dart';
import 'package:ebon_tracker/widgets/categories.dart';
import 'package:flutter/material.dart';

import '../application/database_service.dart';
import '../data/category.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.categories, this.selected});
  final List<Category> categories;
  final Category? selected;

  @override
  CategoryState createState() {
    return CategoryState();
  }
}

class CategoryState extends State<CategoryPage> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  Category? _parent;

  @override
  Widget build(BuildContext context, [bool mounted = true]) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final form = _formKey.currentState;
              if (form != null) {
                if (form.validate()) {
                  form.save();
                  if (widget.selected != null) {
                    await CategoriesDb.update(Category(
                        id: widget.selected!.id,
                        name: _name!,
                        parentId: _parent?.id));
                  } else {
                    await CategoriesDb.insert(_name!, _parent?.id);
                  }
                  setCategories(await CategoriesDb.all());
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Form(
          key: _formKey,
          child: Container(
            margin: const EdgeInsets.only(left: 20.0, right: 20.0),
            child: Column(children: [
              TextFormField(
                initialValue: widget.selected?.name,
                decoration: const InputDecoration(label: Text("Name")),
                // The validator receives the text that the user has entered.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                onSaved: (val) => setState(() {
                  _name = val;
                }),
              ),
              DropdownButtonFormField<Category>(
                value: _parent,
                decoration: InputDecoration(label: Text("Parent")),
                items: widget.categories
                    .map((Category category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        ))
                    .toList(),
                onChanged: (Category? value) => _parent = value,
              )
            ]),
          )),
    );
  }
}
