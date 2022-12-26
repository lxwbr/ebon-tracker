import 'package:ebon_tracker/data/category.dart';
import 'package:redux/redux.dart';
import '../store.dart';
import 'categories_state.dart';

class CategoriesStateAction {
  final CategoriesState categoriesState;

  const CategoriesStateAction(this.categoriesState);
}

void setCategories(List<Category> categories) {
  Redux.store
      .dispatch(CategoriesStateAction(CategoriesState(categories: categories)));
}

void addCategory(Category category) {
  Redux.store.dispatch(CategoriesStateAction(CategoriesState(categories: [
    category,
    ...Redux.store.state.categoriesState.categories
  ])));
}
