import 'package:flutter/material.dart';
import 'helper.dart';
import 'order_model.dart';
import 'order_repository.dart';
import 'session_helper.dart';

class OrderManagementPage extends StatefulWidget {
  final SessionHelper session;
  final String title;
  const OrderManagementPage({
    super.key,
    required this.session,
    this.title = 'Quản lý đơn hàng',
  });

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  late OrderRepository _repository;
  List<OrderModel> _orders = [];
  List<Map<String, String>> _statuses = [];
  String? _orderId;
  String? _status;
  final TextEditingController _search = TextEditingController();
  DateTime? _filterDate;

  void _loadStatuses() async {
    var data = await _repository.getStatuses();
    setState(() {
      _statuses = data;
    });
  }

  void _loadOrders() async {
    DateTime? fromDate;
    DateTime? toDate;
    if (_filterDate != null) {
      fromDate = DateTime(_filterDate!.year, _filterDate!.month, _filterDate!.day);
      toDate = DateTime(_filterDate!.year, _filterDate!.month, _filterDate!.day, 23, 59, 59);
    }
    var data = await _repository.getOrders(
      search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      fromDate: fromDate,
      toDate: toDate,
    );
    setState(() {
      _orders = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _repository = OrderRepository(widget.session.api);
    _loadOrders();
    _loadStatuses();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _loadListView() {
    return Expanded(
      child: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          OrderModel item = _orders[index];
          return ListTile(
            leading: Text(item.orderNumber),
            title: Text('${item.customerName} - ${item.playDate}'),
            subtitle: Text('${item.statusText} • ${item.totalAmount.toStringAsFixed(0)} đ'),
            trailing: ElevatedButton.icon(
              onPressed: () => _onDetails(item),
              label: const Text('Details'),
              icon: const Icon(Icons.details),
            ),
          );
        },
      ),
    );
  }

  void _onDetails(OrderModel obj) async {
    _orderId = obj.orderId;
    _status = obj.status;

    var result = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(obj.orderNumber),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khách: ${obj.customerName}'),
                  Text('SĐT: ${obj.customerPhone}'),
                  Text('Ngày chơi: ${obj.playDate}'),
                  Text('Tổng tiền: ${obj.totalAmount.toStringAsFixed(0)} đ'),
                  if (obj.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Chi tiết:'),
                    ...obj.items.map((i) => Text('- ${i.productName} x ${i.quantity}')),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _statuses.any((s) => s['code'] == _status) ? _status : null,
                    items: _statuses.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['code'],
                        child: Text(p['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      setDialogState(() {
                        _status = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: _onCancel,
                  label: const Text('Cancel'),
                  icon: const Icon(Icons.cancel),
                ),
                ElevatedButton.icon(
                  onPressed: _onSave,
                  label: const Text('Save'),
                  icon: const Icon(Icons.save),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == true) {
      _loadOrders();
    }
  }

  void _onCancel() async {
    Navigator.pop(context, false);
  }

  void _onSave() async {
    if (_orderId != null && _status != null) {
      try {
        await _repository.updateStatus(_orderId!, _status!);
        if (!mounted) return;
        showMessage(context, 'Update success');
      } catch (_) {
        if (!mounted) return;
        showMessage(context, 'Update failed');
      }
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm đơn hàng',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _loadOrders(),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _loadOrders,
                  label: const Text('Tìm'),
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  tooltip: _filterDate == null
                      ? 'Lọc ngày'
                      : 'Ngày: ${_filterDate!.day}/${_filterDate!.month}/${_filterDate!.year}',
                  icon: Icon(
                    Icons.calendar_month,
                    color: _filterDate != null ? Colors.blue : null,
                  ),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _filterDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _filterDate = picked;
                      });
                      _loadOrders();
                    }
                  },
                ),
                if (_filterDate != null)
                  IconButton(
                    tooltip: 'Xóa lọc ngày',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _filterDate = null;
                      });
                      _loadOrders();
                    },
                  ),
              ],
            ),
          ),
          if (_orders.isNotEmpty) ...[
            _loadListView(),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text('Không có dữ liệu'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
