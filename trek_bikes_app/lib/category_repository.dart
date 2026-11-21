import 'api_client.dart';
import 'category.dart';

class CategoryRepository {
  final ApiClient api;
  CategoryRepository(this.api);
  Future<Map<String, dynamic>> getCategories({
    String search = '',
    int page = 1,
  }) async {
    return await api.call(
      'GET',
      '/admin/category?search=${Uri.encodeQueryComponent(search)}&pageIndex=$page&pageSize=10',
    );
  }

  Future<List<Category>> getOptions() async {
    final result = <Category>[];
    int page = 1;
    while (true) {
      final data = await api.call(
        'GET',
        '/admin/category?pageIndex=$page&pageSize=100',
      );
      result.addAll((data['items'] as List).map((x) => Category.fromMap(x)));
      if (page >= data['totalPages']) return result;
      page++;
    }
  }

  Future<Category> getCategory(int id) async {
    return Category.fromMap(await api.call('GET', '/admin/category/$id'));
  }

  Future<Category> save(
    int? id,
    Map<String, String> fields, {
    List<int>? image,
    String? filename,
  }) async {
    return Category.fromMap(
      await api.upload(
        id == null ? 'POST' : 'PUT',
        '/admin/category${id == null ? '' : '/$id'}',
        fields,
        image: image,
        filename: filename,
      ),
    );
  }

  Future<void> delete(Category category) async {
    await api.call(
      'DELETE',
      '/admin/category/${category.id}?rowVersion=${Uri.encodeQueryComponent(category.rowVersion)}',
    );
  }
}
