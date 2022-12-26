import 'categories_actions.dart';
import 'categories_state.dart';

categoriesReducer(CategoriesState prevState, CategoriesStateAction action) {
  return prevState.copyWith(categories: action.categoriesState.categories);
}
