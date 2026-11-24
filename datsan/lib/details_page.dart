import 'package:flutter/material.dart';
import 'api_client.dart';
import 'cart_repository.dart';
import 'helper.dart';
import 'product.dart';
import 'product_repository.dart';
import 'session_helper.dart';

class DetailsPage extends StatefulWidget {
  final SessionHelper session;
  const DetailsPage({super.key, required this.session});

  @override
  State<StatefulWidget> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  int? _id;
  Product? _product;
  late CartRepository _cartRepo;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _id = ModalRoute.of(context)!.settings.arguments as int;
    _cartRepo = CartRepository(widget.session.api);
    _loadProduct();
  }

  void _loadProduct() async {
    if (_id != null) {
      try {
        var item = await ProductRepository(widget.session.api).getProduct(_id!);
        setState(() {
          _product = item;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Widget _loadTable(Product p) {
    return Table(
      columnWidths: const {0: FixedColumnWidth(130)},
      children: [
        TableRow(children: [const Text('Danh mục'), Text(p.categoryName)]),
        TableRow(children: [const Text('Cơ sở'), Text(p.venueName)]),
        TableRow(children: [const Text('Loại'), Text(p.type == 'Court' ? 'Sân thi đấu' : 'Dịch vụ')]),
        TableRow(children: [const Text('Đơn vị'), Text(p.unit)]),
        if (p.capacity != null)
          TableRow(children: [const Text('Sức chứa'), Text('${p.capacity} người')]),
        if (p.indoor != null)
          TableRow(children: [const Text('Trong nhà'), Text(p.indoor! ? 'Có' : 'Không')]),
        if (p.surface != null)
          TableRow(children: [const Text('Mặt sân'), Text(p.surface!)]),
        if (p.openTime != null && p.closeTime != null)
          TableRow(children: [const Text('Giờ mở cửa'), Text('${p.openTime} - ${p.closeTime}')]),
        if (p.peakStartTime != null && p.peakEndTime != null && p.peakPrice != null)
          TableRow(children: [
            const Text('Giờ vàng'),
            Text('${p.peakStartTime}-${p.peakEndTime}: ${p.peakPrice!.toStringAsFixed(0)} đ/${p.unit}'),
          ]),
        if (p.description != null && p.description!.isNotEmpty)
          TableRow(children: [const Text('Mô tả'), Text(p.description!)]),
      ],
    );
  }

  void _onAddToCart() async {
    if (widget.session.member == null) {
      showMessage(context, 'Bạn phải đăng nhập để thêm vào giỏ hàng');
      return;
    }
    try {
      int ret = await _cartRepo.addToCart(_id!);
      if (!mounted) return;
      if (ret > 0) {
        showMessage(context, 'Thêm vào giỏ hàng thành công');
      } else {
        showMessage(context, 'Thêm vào giỏ hàng thất bại');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showMessage(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết')),
      body: Column(
        children: [
          if (_product != null) ...[
            if (_product!.imagePath != null && _product!.imagePath!.isNotEmpty)
              Image.network(
                _product!.imagePath!.startsWith('/')
                    ? '${widget.session.api.baseUrl}${_product!.imagePath}'
                    : '${widget.session.api.baseUrl}/uploads/${_product!.imagePath}',
                width: 256,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Icon(Icons.sports_tennis, size: 80),
              ),
            Text(_product!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Giá: ${_product!.basePrice.toStringAsFixed(0)} đ/${_product!.unit}'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _loadTable(_product!),
            ),
            ElevatedButton.icon(
              onPressed: _onAddToCart,
              label: const Text('Add to Cart'),
              icon: const Icon(Icons.add_shopping_cart),
            ),
            if (_error != null) Text('Lỗi: $_error'),
          ] else if (_error != null)
            Text('Không tìm thấy: $_id\n$_error')
          else
            const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
