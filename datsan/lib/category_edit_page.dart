import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'category.dart';
import 'category_repository.dart';
import 'session_helper.dart';
import 'helper.dart';
import 'catalog_image.dart';

class CategoryEditPage extends StatefulWidget {
  final SessionHelper session;
  final int? id;
  const CategoryEditPage({super.key, required this.session, this.id});
  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      description = TextEditingController(),
      order = TextEditingController(text: '0');
  late CategoryRepository repository;
  late Future<dynamic> data;
  Category? current;
  Uint8List? image;
  String? filename, error;
  bool active = true, busy = false;
  @override
  void initState() {
    super.initState();
    repository = CategoryRepository(widget.session.api);
    data = load();
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    order.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (widget.id == null) return;
    current = await repository.getCategory(widget.id!);
    name.text = current!.name;
    description.text = current!.description ?? '';
    order.text = '${current!.displayOrder}';
    active = current!.isActive;
  }

  Future<void> pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Ảnh cần nhỏ hơn hoặc bằng 5 MB.');
      }
      if (mounted) {
        setState(() {
          image = bytes;
          filename = file.name;
        });
      }
    } catch (e) {
      if (mounted) showMessage(context, e);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await repository.save(
        widget.id,
        {
          'name': name.text.trim(),
          'description': description.text.trim(),
          'displayOrder': order.text,
          'isActive': '$active',
          if (current != null) 'rowVersion': current!.rowVersion,
        },
        image: image,
        filename: filename,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Thêm danh mục' : 'Chỉnh sửa danh mục'),
      ),
      body: RequestView(
        future: data,
        retry: () => setState(() => data = load()),
        builder: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (image != null)
                      Image.memory(image!, height: 160, fit: BoxFit.contain)
                    else
                      CatalogImage(
                        api: widget.session.api,
                        path: current?.imagePath,
                        size: 140,
                      ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(filename ?? 'Chọn ảnh danh mục (tùy chọn)'),
                    ),
                    TextFormField(
                      controller: name,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Tên danh mục',
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Nhập tên danh mục' : null,
                    ),
                    TextFormField(
                      controller: description,
                      maxLength: 1000,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    TextFormField(
                      controller: order,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự hiển thị',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 0 || n > 10000
                            ? 'Nhập số từ 0 đến 10000'
                            : null;
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hiển thị danh mục'),
                      value: active,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => active = v),
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (error != null && current != null)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() => data = load()),
                        child: const Text('Tải dữ liệu mới'),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: busy ? null : save,
                      child: Text(busy ? 'Đang lưu…' : 'Lưu danh mục'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
