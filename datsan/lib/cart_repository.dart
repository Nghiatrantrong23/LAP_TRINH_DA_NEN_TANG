import 'api_client.dart';

class CartModel {
  final int id;
  final int productId;
  final String name;
  final String type;
  final String unit;
  final String? imagePath;
  final double basePrice;
  final int quantity;
  double get amount => basePrice * quantity;

  CartModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.type,
    required this.unit,
    required this.basePrice,
    required this.quantity,
    this.imagePath,
  });

  factory CartModel.fromMap(Map<String, dynamic> m) {
    return CartModel(
      id: (m['id'] as num).toInt(),
      productId: (m['productId'] as num).toInt(),
      name: m['name'] ?? '',
      type: m['type'] ?? '',
      unit: m['unit'] ?? '',
      imagePath: m['imagePath'],
      basePrice: (m['basePrice'] as num).toDouble(),
      quantity: (m['quantity'] as num).toInt(),
    );
  }
}

class CartRepository {
  final ApiClient api;
  CartRepository(this.api);

  Future<List<CartModel>> getCart() async {
    final res = await api.call('GET', '/cart');
    if (res is List) return res.map((e) => CartModel.fromMap(e)).toList();
    return [];
  }

  Future<int> getCount() async {
    final res = await api.call('GET', '/cart/count');
    return (res as num?)?.toInt() ?? 0;
  }

  Future<int> addToCart(int productId, {int quantity = 1}) async {
    final res = await api.call('POST', '/cart', body: {
      'productId': productId,
      'quantity': quantity,
    });
    return (res as num?)?.toInt() ?? 0;
  }

  Future<int> updateQuantity(int itemId, int quantity) async {
    final res = await api.call('PUT', '/cart/$itemId', body: {
      'quantity': quantity,
    });
    return (res as num?)?.toInt() ?? 0;
  }

  Future<int> deleteItem(int itemId) async {
    final res = await api.call('DELETE', '/cart/$itemId');
    return (res as num?)?.toInt() ?? 0;
  }
}
