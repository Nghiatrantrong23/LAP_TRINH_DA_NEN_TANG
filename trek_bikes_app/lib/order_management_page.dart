import 'package:flutter/material.dart';

import 'helper.dart';
import 'order_model.dart';
import 'order_repository.dart';
import 'session_helper.dart';

class OrderManagementPage extends StatefulWidget {
  final SessionHelper session;
  const OrderManagementPage({super.key, required this.session});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  late OrderRepository _repository;
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'ALL';
  String _datePreset = 'all'; // all, today, 7days, custom
  DateTimeRange? _selectedDateRange;

  String _formatCurrency(num amount) {
    String str = amount.toStringAsFixed(0);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '$result đ';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  final List<Map<String, String>> _statusOptions = [
    {'code': 'ChoCoc', 'name': 'Chờ cọc'},
    {'code': 'DaXacNhan', 'name': 'Đã xác nhận'},
    {'code': 'DangChoi', 'name': 'Đang chơi'},
    {'code': 'HoanThanh', 'name': 'Hoàn thành'},
    {'code': 'DaHuy', 'name': 'Đã hủy'},
  ];

  @override
  void initState() {
    super.initState();
    _repository = OrderRepository(widget.session.api);
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      DateTime? fromDate;
      DateTime? toDate;

      if (_datePreset == 'today') {
        final now = DateTime.now();
        fromDate = DateTime(now.year, now.month, now.day);
        toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (_datePreset == '7days') {
        final now = DateTime.now();
        fromDate = now.subtract(const Duration(days: 7));
        toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (_datePreset == 'custom' && _selectedDateRange != null) {
        fromDate = _selectedDateRange!.start;
        toDate = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
      }

      var list = await _repository.getOrders(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (mounted) {
        setState(() {
          _orders = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showMessage(context, 'Lỗi tải đơn hàng: $e');
      }
    }
  }

  void _onSelectCustomDate() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      helpText: 'Chọn khoảng ngày đặt chơi',
      cancelText: 'Hủy',
      confirmText: 'Áp dụng',
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _datePreset = 'custom';
      });
      _loadOrders();
    }
  }

  void _showUpdateStatusDialog(OrderModel order) {
    String newStatus = order.status;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Cập nhật trạng thái #${order.orderNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khách hàng: ${order.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Số điện thoại: ${order.customerPhone}'),
                Text('Tổng tiền: ${_formatCurrency(order.totalAmount)}'),
                const SizedBox(height: 16),
                const Text('Chọn trạng thái mới:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _statusOptions.any((s) => s['code'] == newStatus) ? newStatus : 'ChoCoc',
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _statusOptions.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt['code'],
                      child: Text(opt['name']!),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => newStatus = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('Lý do thay đổi (tùy chọn):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Nhập ghi chú hoặc lý do thay đổi trạng thái...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await _repository.updateStatus(
                    order.orderId,
                    newStatus,
                    reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                  );
                  if (mounted) {
                    showMessage(context, 'Cập nhật trạng thái thành công');
                    _loadOrders();
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    showMessage(context, 'Lỗi cập nhật trạng thái: $e');
                  }
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetailSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn: #${order.orderNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: order.statusColor),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        color: order.statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Thông tin người đặt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Text('Họ và tên: ${order.customerName}'),
              Text('Số điện thoại: ${order.customerPhone}'),
              Text('Ngày chơi: ${order.playDate}'),
              Text('Thời gian tạo: ${_formatDateTime(order.createdAt)}'),
              if (order.note != null && order.note!.isNotEmpty)
                Text('Ghi chú: ${order.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
              const Divider(height: 24),
              const Text('Chi tiết sân & dịch vụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (order.items.isEmpty)
                const Text('Chưa có thông tin chi tiết mặt hàng.', style: TextStyle(color: Colors.grey))
              else
                ...order.items.map((item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey.shade50,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isCourt ? Colors.green.shade100 : Colors.blue.shade100,
                          child: Icon(
                            item.isCourt ? Icons.sports_tennis : Icons.room_service,
                            color: item.isCourt ? Colors.green.shade800 : Colors.blue.shade800,
                            size: 20,
                          ),
                        ),
                        title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item.quantity} ${item.unit} x ${_formatCurrency(item.unitPrice ?? 0)}'),
                        trailing: Text(
                          _formatCurrency(item.totalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiền cọc:', style: TextStyle(fontSize: 14)),
                  Text(_formatCurrency(order.depositAmount), style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền đơn hàng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    _formatCurrency(order.totalAmount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text('Cập nhật trạng thái đơn này'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showUpdateStatusDialog(order);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalCount = _orders.length;
    int choCocCount = _orders.where((o) => o.status == 'ChoCoc' || o.status == 'PendingDeposit').length;
    int daXacNhanCount = _orders.where((o) => o.status == 'DaXacNhan' || o.status == 'Confirmed').length;
    int hoanThanhCount = _orders.where((o) => o.status == 'HoanThanh' || o.status == 'Completed').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Thống kê nhanh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Tổng đơn', totalCount.toString(), Colors.blueGrey),
                _buildStatItem('Chờ cọc', choCocCount.toString(), Colors.orange),
                _buildStatItem('Đã xác nhận', daXacNhanCount.toString(), Colors.blue),
                _buildStatItem('Hoàn thành', hoanThanhCount.toString(), Colors.green),
              ],
            ),
          ),

          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn, tên khách, số điện thoại...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadOrders();
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _loadOrders(),
            ),
          ),

          // Bộ lọc ngày & trạng thái
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Ngày: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _datePreset == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _datePreset = 'all';
                              _selectedDateRange = null;
                            });
                            _loadOrders();
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Hôm nay'),
                        selected: _datePreset == 'today',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _datePreset = 'today');
                            _loadOrders();
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('7 ngày qua'),
                        selected: _datePreset == '7days',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _datePreset = '7days');
                            _loadOrders();
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _datePreset == 'custom' && _selectedDateRange != null
                              ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                              : 'Chọn ngày...',
                          style: TextStyle(
                            color: _datePreset == 'custom' ? Theme.of(context).primaryColor : null,
                            fontWeight: _datePreset == 'custom' ? FontWeight.bold : null,
                          ),
                        ),
                        onPressed: _onSelectCustomDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStatus,
                        underline: Container(height: 1, color: Colors.grey.shade300),
                        items: [
                          const DropdownMenuItem(value: 'ALL', child: Text('Tất cả trạng thái')),
                          ..._statusOptions.map((opt) => DropdownMenuItem(
                                value: opt['code'],
                                child: Text(opt['name']!),
                              )),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStatus = val);
                            _loadOrders();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Danh sách đơn hàng
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Không có đơn hàng nào phù hợp',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: _orders.length,
                        itemBuilder: (ctx, idx) {
                          final order = _orders[idx];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#${order.orderNumber}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: order.statusBgColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: order.statusColor),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(order.statusIcon, size: 14, color: order.statusColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              order.statusText,
                                              style: TextStyle(
                                                color: order.statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        order.customerName,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(order.customerPhone),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.event, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('Ngày chơi: ${order.playDate}'),
                                      const Spacer(),
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(_formatDate(order.createdAt)),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${order.itemCount} mục | Cọc: ${_formatCurrency(order.depositAmount)}',
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      ),
                                      Text(
                                        _formatCurrency(order.totalAmount),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.visibility, size: 16),
                                        label: const Text('Chi tiết'),
                                        onPressed: () => _showOrderDetailSheet(order),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Đổi trạng thái'),
                                        onPressed: () => _showUpdateStatusDialog(order),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, MaterialColor color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color.shade800,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
