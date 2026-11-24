import 'package:flutter/material.dart';
import 'cart_repository.dart';
import 'helper.dart';
import 'session_helper.dart';

class CartPage extends StatefulWidget {
  final SessionHelper session;
  const CartPage({super.key, required this.session});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late CartRepository _repository;
  List<CartModel> _carts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = CartRepository(widget.session.api);
    _loadCarts();
  }

  void _loadCarts() async {
    var data = await _repository.getCart();
    setState(() {
      _carts = data;
      _error = null;
    });
  }

  Widget _loadTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Sản phẩm')),
          DataColumn(label: Text('Đơn giá')),
          DataColumn(label: Text('SL')),
          DataColumn(label: Text('Thành tiền')),
          DataColumn(label: Text('Thao tác')),
        ],
        rows: _carts.map((p) {
          return DataRow(cells: [
            DataCell(Text(p.name)),
            DataCell(Text('${p.basePrice.toStringAsFixed(0)} đ')),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: p.quantity > 1
                        ? () => _onUpdateQuantity(p.id, p.quantity - 1)
                        : null,
                  ),
                  Text(p.quantity.toString()),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _onUpdateQuantity(p.id, p.quantity + 1),
                  ),
                ],
              ),
            ),
            DataCell(Text('${p.amount.toStringAsFixed(0)} đ')),
            DataCell(
              ElevatedButton.icon(
                onPressed: () => _onDelete(p.id),
                label: const Text('Delete'),
                icon: const Icon(Icons.delete),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  void _onUpdateQuantity(int id, int newQty) async {
    int ret = await _repository.updateQuantity(id, newQty);
    if (ret > 0) {
      _loadCarts();
    }
  }

  void _onDelete(int id) async {
    int ret = await _repository.deleteItem(id);
    if (ret > 0) {
      _loadCarts();
    } else {
      setState(() {
        _error = 'Delete failed $ret';
      });
    }
  }

  void _onCheckout() async {
    if (_carts.isEmpty) {
      showMessage(context, 'Giỏ hàng trống');
      return;
    }
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đặt sân'),
        content: Text(
          'Tổng ${_carts.fold(0.0, (s, e) => s + e.amount).toStringAsFixed(0)} đ\n'
          'Xác nhận đặt ${_carts.length} mục?',
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, false),
            label: const Text('Huỷ'),
            icon: const Icon(Icons.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Đặt sân'),
            icon: const Icon(Icons.shopping_cart_checkout),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (!mounted) return;
      showMessage(context, 'Đặt sân thành công! Nhân viên sẽ liên hệ xác nhận.');
      _loadCarts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: Column(
        children: [
          _loadTable(),
          if (_error != null) Text(_error!),
          if (_carts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Tổng: ${_carts.fold(0.0, (s, e) => s + e.amount).toStringAsFixed(0)} đ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _onCheckout,
            label: const Text('Checkout'),
            icon: const Icon(Icons.shopping_cart_checkout),
          ),
        ],
      ),
    );
  }
}
