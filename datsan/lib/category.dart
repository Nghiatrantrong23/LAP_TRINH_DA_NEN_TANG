class Category {
  final int id, displayOrder;
  final String name, rowVersion;
  final String? description, imagePath;
  final bool isActive;
  const Category({
    required this.id,
    required this.name,
    required this.rowVersion,
    this.description,
    this.imagePath,
    this.displayOrder = 0,
    this.isActive = true,
  });
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: (map['id'] as num?)?.toInt() ?? 0,
      name: map['name'] ?? '',
      rowVersion: map['rowVersion'] ?? '',
      description: map['description'],
      imagePath: map['imagePath'],
      displayOrder: (map['displayOrder'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }
}
