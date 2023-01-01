import 'package:ebon_tracker/data/category.dart';

class Product {
  final String name;
  final Category? category;

  const Product({
    required this.name,
    this.category,
  });

  static List<String> headers = ["name", "category"];

  List<String> get toCsv => [name.toString(), category?.name ?? ""];

  @override
  String toString() {
    return "$name: $category";
  }

  Map<String, dynamic> toMap() => {'name': name, 'category': category?.id};

  factory Product.fromMap(Map<String, dynamic> map) {
    Category? category;
    if (map['categoryId'] != null && map['categoryName'] != null) {
      category = Category(id: map['categoryId'], name: map['categoryName']);
    }
    return Product(name: map['name'] ?? '', category: category);
  }
}
