import 'package:ebon_tracker/data/category.dart';
import 'package:meta/meta.dart';

@immutable
class CategoriesState {
  final List<Category> categories;

  const CategoriesState({required this.categories});

  factory CategoriesState.initial() => const CategoriesState(categories: []);

  CategoriesState copyWith({required List<Category> categories}) {
    return CategoriesState(categories: categories);
  }
}
