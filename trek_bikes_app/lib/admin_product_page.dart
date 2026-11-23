import 'package:flutter/material.dart';

import 'product.dart';
import 'product_repository.dart';
import 'product_edit_page.dart';
import 'session_helper.dart';
import 'helper.dart';
import 'catalog_image.dart';

class AdminProductPage extends StatefulWidget {
  final SessionHelper session;
  const AdminProductPage({super.key, required this.session});
  @override
  State<AdminProductPage> createState() => _AdminProductPageState();
}

class _AdminProductPageState extends State<AdminProductPage> {
  late ProductRepository repository;
  late Future<dynamic> data;
  final search = TextEditingController();
  int page = 1;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    repository = ProductRepository(widget.session.api);
    reload();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reload() {
    data = repository.getProducts(search: search.text, page: page, admin: true);
  }

  Future<void> edit([int? id]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductEditPage(session: widget.session, id: id),
      ),
    );
    if (mounted) setState(reload);
  }

  Future<void> remove(Product item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa mục này?'),
        content: Text(item.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => busy = true);
    try {
      await repository.delete(item);
      if (mounted) {
        showMessage(context, 'Đã xóa.');
        setState(reload);
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, e);
        setState(reload);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      if (widget.session.member?.isAdmin != true) {
        return Scaffold(
          appBar: AppBar(title: const Text('Quản trị')),
          body: const Center(
            child: Text('Cần đăng nhập bằng tài khoản Admin.'),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý sân & dịch vụ'),
          actions: [
            IconButton(
              tooltip: 'Tải lại',
              onPressed: busy ? null : () => setState(reload),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: busy ? null : () => edit(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm mới'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: search,
                onSubmitted: (_) => setState(() {
                  page = 1;
                  reload();
                }),
                decoration: InputDecoration(
                  labelText: 'Tìm theo tên',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      page = 1;
                      reload();
                    }),
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
            ),
            if (busy) const LinearProgressIndicator(),
            Expanded(
              child: RequestView(
                future: data,
                retry: () => setState(reload),
                builder: (value) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  children: [
                    if ((value['items'] as List).isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text('Không có kết quả.'),
                      ),
                    for (final raw in value['items'])
                      Builder(
                        builder: (context) {
                          final item = Product.fromMap(raw);
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CatalogImage(
                                api: widget.session.api,
                                path: item.imagePath,
                              ),
                              title: Text(item.name),
                              subtitle: Text(
                                '${item.categoryName} • ${formatMoney(item.basePrice)}/${item.unit} • ${item.isActive ? 'Hoạt động' : 'Ngừng hoạt động'}',
                              ),
                              onTap: busy ? null : () => edit(item.id),
                              trailing: PopupMenuButton<String>(
                                enabled: !busy,
                                onSelected: (action) => action == 'delete'
                                    ? remove(item)
                                    : edit(item.id),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Chỉnh sửa'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Xóa'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: page > 1 && !busy
                              ? () => setState(() {
                                  page--;
                                  reload();
                                })
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text(
                          'Trang $page / ${value['totalPages'] == 0 ? 1 : value['totalPages']}',
                        ),
                        IconButton(
                          onPressed: page < value['totalPages'] && !busy
                              ? () => setState(() {
                                  page++;
                                  reload();
                                })
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
