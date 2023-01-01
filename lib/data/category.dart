class Category {
  final int id;
  final int? parentId;
  final String name;

  const Category({
    required this.id,
    this.parentId,
    required this.name,
  });

  Map<String, dynamic> toMap() =>
      {'id': id, 'parentId': parentId, 'name': name};

  List<String> get toCsv =>
      [id.toString(), name.toString(), parentId?.toString() ?? ""];

  static List<String> headers = ["id", "name", "parentId"];

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] ?? 0,
        parentId: map['parentId'],
        name: map['name'] ?? '',
      );

  @override
  String toString() => 'Category(id: $id, name: $name, parent: $parentId)';
}
