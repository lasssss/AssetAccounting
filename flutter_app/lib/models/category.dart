class Category {
  final int? id;
  final String name;

  Category({this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Category.fromMap(Map<String, dynamic> m) =>
      Category(id: m['id'], name: m['name']);

  @override
  String toString() => name;
}