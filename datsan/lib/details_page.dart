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
  List<Product> _related = [];
  int _relatedPage = 1;
  int _relatedTotalPages = 1;
  late CartRepository _cartRepo;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)!.settings.arguments as int;
    if (_id != arg) {
      _id = arg;
      _relatedPage = 1;
      _cartRepo = CartRepository(widget.session.api);
      _loadProduct();
    }
  }

  void _loadProduct() async {
    if (_id != null) {
      try {
        var item = await ProductRepository(widget.session.api).getProduct(_id!);
        if (!mounted) return;
        setState(() {
          _product = item;
        });
        _loadRelated(item.categoryId);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _loadRelated(int categoryId) async {
    try {
      final res = await ProductRepository(widget.session.api).getProducts(
        categoryId: categoryId,
        page: _relatedPage,
        pageSize: 4,
      );
      if (!mounted) return;
      if (res['items'] is List) {
        final list = (res['items'] as List)
            .map((e) => Product.fromMap(e))
            .where((p) => p.id != _id)
            .toList();
        setState(() {
          _related = list;
          _relatedTotalPages = (res['totalPages'] as int?) ?? 1;
          if (_relatedTotalPages < 1) _relatedTotalPages = 1;
        });
      }
    } catch (_) {}
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
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
              const Divider(height: 28),
              const Text(
                'Sản phẩm liên quan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_related.isEmpty)
                const Text('Không có sản phẩm liên quan.')
              else ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _related.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final item = _related[index];
                    return InkWell(
                      onTap: () => Navigator.pushNamed(context, '/details', arguments: item.id),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (item.imagePath != null && item.imagePath!.isNotEmpty)
                                Image.network(
                                  item.imagePath!.startsWith('/')
                                      ? '${widget.session.api.baseUrl}${item.imagePath}'
                                      : '${widget.session.api.baseUrl}/uploads/${item.imagePath}',
                                  width: 100,
                                  height: 65,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) =>
                                      const Icon(Icons.sports_tennis, size: 40),
                                )
                              else
                                const Icon(Icons.sports_tennis, size: 40),
                              const SizedBox(height: 4),
                              Text(item.name, overflow: TextOverflow.ellipsis),
                              Text('${item.basePrice.toStringAsFixed(0)} đ/${item.unit}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _relatedPage > 1
                          ? () {
                              setState(() => _relatedPage--);
                              _loadRelated(_product!.categoryId);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Trang $_relatedPage / $_relatedTotalPages'),
                    IconButton(
                      onPressed: _relatedPage < _relatedTotalPages
                          ? () {
                              setState(() => _relatedPage++);
                              _loadRelated(_product!.categoryId);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ] else if (_error != null)
              Text('Không tìm thấy: $_id\n$_error')
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
