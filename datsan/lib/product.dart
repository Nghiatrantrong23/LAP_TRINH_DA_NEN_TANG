class Product {
  final int id, categoryId, venueId;
  final String name, type, unit, rowVersion, categoryName, venueName;
  final String? description,
      imagePath,
      surface,
      openTime,
      closeTime,
      peakStartTime,
      peakEndTime;
  final double basePrice;
  final double? peakPrice;
  final int? capacity;
  final bool isActive;
  final bool? indoor;
  const Product({
    required this.id,
    required this.categoryId,
    required this.venueId,
    required this.name,
    required this.type,
    required this.unit,
    required this.rowVersion,
    required this.categoryName,
    required this.venueName,
    required this.basePrice,
    required this.isActive,
    this.description,
    this.imagePath,
    this.surface,
    this.openTime,
    this.closeTime,
    this.peakStartTime,
    this.peakEndTime,
    this.peakPrice,
    this.capacity,
    this.indoor,
  });
  factory Product.fromMap(Map<String, dynamic> m) {
    return Product(
      id: (m['id'] as num?)?.toInt() ?? 0,
      categoryId: (m['categoryId'] as num?)?.toInt() ?? 0,
      venueId: (m['venueId'] as num?)?.toInt() ?? 0,
      name: m['name'] ?? '',
      type: m['type'] ?? '',
      unit: m['unit'] ?? '',
      rowVersion: m['rowVersion'] ?? '',
      categoryName: m['categoryName'] ?? '',
      venueName: m['venueName'] ?? '',
      basePrice: ((m['basePrice'] ?? 0) as num).toDouble(),
      isActive: m['isActive'] ?? true,
      description: m['description'],
      imagePath: m['imagePath'],
      surface: m['surface'],
      openTime: m['openTime'],
      closeTime: m['closeTime'],
      peakStartTime: m['peakStartTime'],
      peakEndTime: m['peakEndTime'],
      peakPrice: (m['peakPrice'] as num?)?.toDouble(),
      capacity: (m['capacity'] as num?)?.toInt(),
      indoor: m['indoor'] as bool?,
    );
  }
}
