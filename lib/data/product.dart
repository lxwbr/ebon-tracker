class Product {
  final String name;
  final int? category;

  const Product({
    required this.name,
    this.category,
  });

  @override
  String toString() {
    return "$name: $category";
  }

  Map<String, dynamic> toMap() => {'name': name, 'category': category};

  factory Product.fromMap(Map<String, dynamic> map) =>
      Product(name: map['name'] ?? '', category: map['category']);
}
