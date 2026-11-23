import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'product.dart';
import 'product_repository.dart';
import 'category.dart';
import 'category_repository.dart';
import 'session_helper.dart';
import 'helper.dart';
import 'catalog_image.dart';

class ProductEditPage extends StatefulWidget {
  final SessionHelper session;
  final int? id;
  const ProductEditPage({super.key, required this.session, this.id});
  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      description = TextEditingController(),
      price = TextEditingController(text: '0'),
      unit = TextEditingController(text: 'giờ');
  final capacity = TextEditingController(text: '4'),
      surface = TextEditingController(),
      open = TextEditingController(text: '06:00'),
      close = TextEditingController(text: '22:00'),
      peakStart = TextEditingController(text: '17:00'),
      peakEnd = TextEditingController(text: '21:00'),
      peakPrice = TextEditingController(text: '0');
  late ProductRepository repository;
  late Future<dynamic> data;
  Product? current;
  List<Category> categories = [];
  List<dynamic> venues = [];
  int? categoryId, venueId;
  String type = 'Court';
  bool active = true, indoor = true, busy = false;
  Uint8List? image;
  String? filename, error;
  @override
  void initState() {
    super.initState();
    repository = ProductRepository(widget.session.api);
    data = load();
  }

  @override
  void dispose() {
    for (final c in [
      name,
      description,
      price,
      unit,
      capacity,
      surface,
      open,
      close,
      peakStart,
      peakEnd,
      peakPrice,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String time(String? value, String fallback) {
    return value == null ? fallback : value.substring(0, 5);
  }

  Future<void> load() async {
    final options = await Future.wait([
      CategoryRepository(widget.session.api).getOptions(),
      repository.getVenues(),
    ]);
    categories = options[0].cast<Category>();
    venues = options[1];
    if (widget.id == null) return;
    current = await repository.getProduct(widget.id!, admin: true);
    final p = current!;
    categoryId = p.categoryId;
    venueId = p.venueId;
    type = p.type;
    active = p.isActive;
    indoor = p.indoor ?? false;
    name.text = p.name;
    description.text = p.description ?? '';
    price.text = p.basePrice.toString();
    unit.text = p.unit;
    capacity.text = '${p.capacity ?? 4}';
    surface.text = p.surface ?? '';
    open.text = time(p.openTime, '06:00');
    close.text = time(p.closeTime, '22:00');
    peakStart.text = time(p.peakStartTime, '17:00');
    peakEnd.text = time(p.peakEndTime, '21:00');
    peakPrice.text = (p.peakPrice ?? p.basePrice).toString();
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

  String? amount(String? value) {
    final n = num.tryParse(value ?? '');
    return n == null || n < 0 || n > 100000000
        ? 'Nhập số tiền từ 0 đến 100.000.000'
        : null;
  }

  String? clock(String? value) {
    if (!RegExp(r'^([01]\d|2[0-3]):(00|30)$').hasMatch(value ?? '')) {
      return 'Dùng HH:mm, phút 00 hoặc 30';
    }
    return null;
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (widget.id == null && image == null) {
      setState(() => error = 'Sản phẩm mới bắt buộc có ảnh.');
      return;
    }
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
          'categoryId': '$categoryId',
          'venueId': '$venueId',
          'type': type,
          'basePrice': price.text,
          'unit': unit.text.trim(),
          'isActive': '$active',
          if (current != null) 'rowVersion': current!.rowVersion,
          if (type == 'Court') ...{
            'capacity': capacity.text,
            'surface': surface.text.trim(),
            'indoor': '$indoor',
            'openTime': open.text,
            'closeTime': close.text,
            'peakStartTime': peakStart.text,
            'peakEndTime': peakEnd.text,
            'peakPrice': peakPrice.text,
          },
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
        title: Text(
          widget.id == null ? 'Thêm sân / dịch vụ' : 'Chỉnh sửa sân / dịch vụ',
        ),
      ),
      body: RequestView(
        future: data,
        retry: () => setState(() => data = load()),
        builder: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (image != null)
                      Image.memory(image!, height: 180, fit: BoxFit.contain)
                    else
                      CatalogImage(
                        api: widget.session.api,
                        path: current?.imagePath,
                        size: 160,
                      ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(filename ?? 'Chọn ảnh sản phẩm'),
                    ),
                    TextFormField(
                      controller: name,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Tên sân / dịch vụ',
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Nhập tên' : null,
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      isExpanded: true,
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.name}${c.isActive ? '' : ' (đã ẩn)'}',
                            ),
                          ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() => categoryId = v),
                      validator: (v) => v == null ? 'Chọn danh mục' : null,
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: venueId,
                      decoration: const InputDecoration(labelText: 'Cơ sở'),
                      isExpanded: true,
                      items: [
                        for (final v in venues)
                          DropdownMenuItem<int>(
                            value: v['id'],
                            child: Text(
                              '${v['name']}${v['isActive'] ? '' : ' (ngừng hoạt động)'}',
                            ),
                          ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() => venueId = v),
                      validator: (v) => v == null ? 'Chọn cơ sở' : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Loại sản phẩm',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Court',
                          child: Text('Sân thể thao'),
                        ),
                        DropdownMenuItem(
                          value: 'Service',
                          child: Text('Dịch vụ / phụ kiện'),
                        ),
                      ],
                      onChanged: busy || current != null
                          ? null
                          : (v) => setState(() {
                              type = v!;
                              unit.text = type == 'Court' ? 'giờ' : 'phần';
                            }),
                    ),
                    TextFormField(
                      controller: description,
                      maxLength: 5000,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    TextFormField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: type == 'Court'
                            ? 'Giá giờ thường (đ/giờ)'
                            : 'Đơn giá (đ)',
                      ),
                      validator: amount,
                    ),
                    TextFormField(
                      controller: unit,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        labelText: 'Đơn vị tính',
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Nhập đơn vị tính' : null,
                    ),
                    if (type == 'Court') ...[
                      const SizedBox(height: 16),
                      Text(
                        'Cấu hình sân',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextFormField(
                        controller: capacity,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sức chứa tối đa',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 2 || n > 100
                              ? 'Nhập số người từ 2 đến 100'
                              : null;
                        },
                      ),
                      TextFormField(
                        controller: surface,
                        maxLength: 100,
                        decoration: const InputDecoration(labelText: 'Mặt sân'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sân trong nhà'),
                        value: indoor,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => indoor = v),
                      ),
                      TextFormField(
                        controller: open,
                        decoration: const InputDecoration(
                          labelText: 'Giờ mở cửa (HH:mm)',
                        ),
                        validator: clock,
                      ),
                      TextFormField(
                        controller: close,
                        decoration: const InputDecoration(
                          labelText: 'Giờ đóng cửa (HH:mm)',
                        ),
                        validator: clock,
                      ),
                      TextFormField(
                        controller: peakStart,
                        decoration: const InputDecoration(
                          labelText: 'Giờ vàng bắt đầu (HH:mm)',
                        ),
                        validator: clock,
                      ),
                      TextFormField(
                        controller: peakEnd,
                        decoration: const InputDecoration(
                          labelText: 'Giờ vàng kết thúc (HH:mm)',
                        ),
                        validator: clock,
                      ),
                      TextFormField(
                        controller: peakPrice,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá giờ vàng (đ/giờ)',
                        ),
                        validator: amount,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Giờ mở cửa và giờ vàng áp dụng giống nhau cho tất cả ngày trong tuần.',
                        ),
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đang hoạt động'),
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
                      child: Text(busy ? 'Đang lưu…' : 'Lưu sản phẩm'),
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
