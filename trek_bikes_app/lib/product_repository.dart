import 'api_client.dart';
import 'product.dart';

class ProductRepository {
  final ApiClient api;
  ProductRepository(this.api);
  Future<Map<String, dynamic>> getProducts({
    String search = '',
    int page = 1,
  }) async {
    return await api.call(
      'GET',
      '/admin/product?search=${Uri.encodeQueryComponent(search)}&pageIndex=$page&pageSize=10',
    );
  }

  Future<Product> getProduct(int id) async {
    return Product.fromMap(await api.call('GET', '/admin/product/$id'));
  }

  Future<List<dynamic>> getVenues() async {
    return await api.call('GET', '/admin/venue');
  }

  Future<Product> save(
    int? id,
    Map<String, String> fields, {
    List<int>? image,
    String? filename,
  }) async {
    return Product.fromMap(
      await api.upload(
        id == null ? 'POST' : 'PUT',
        '/admin/product${id == null ? '' : '/$id'}',
        fields,
        image: image,
        filename: filename,
      ),
    );
  }

  Future<void> delete(Product product) async {
    await api.call(
      'DELETE',
      '/admin/product/${product.id}?rowVersion=${Uri.encodeQueryComponent(product.rowVersion)}',
    );
  }
}
