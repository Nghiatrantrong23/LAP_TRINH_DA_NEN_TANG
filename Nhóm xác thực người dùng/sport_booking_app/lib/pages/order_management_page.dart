import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/helpers/session_helper.dart';
import 'package:sport_booking_app/models/order_model.dart';
import 'package:sport_booking_app/repositories/order_repository.dart';

// Quản lý đơn hàng (Admin)
// 1. Hiển thị danh sách đơn hàng (Bắt buộc - 0.25đ)
// 2. Cập nhật trạng thái đơn hàng (Bắt buộc - 0.50đ)
// 3. Tìm kiếm đơn hàng (Điểm cộng - 0.25đ)
// 4. Lọc đơn hàng theo ngày (Điểm cộng - 0.25đ)
// 5. Kết nối API backend (0.25đ)
class OrderManagementPage extends StatefulWidget {
  final String title;
  const OrderManagementPage({super.key, required this.title});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  // 3. Tìm kiếm đơn hàng
  final TextEditingController _searchController = TextEditingController();

  // 4. Lọc đơn hàng
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
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() async {
    setState(() => _isLoading = true);
    String? token = await SessionHelper.token;
    if (token != null) {
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

      var list = await OrderRepository.getOrders(
        token,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
        fromDate: fromDate,
        toDate: toDate,
      );

      setState(() {
        _orders = list;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // 2. CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG (0.50đ)
  void _onUpdateStatus(OrderModel order) async {
    String currentStatus = order.status;
    String newStatus = currentStatus;
    final reasonController = TextEditingController();

    var result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Cập nhật trạng thái', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đơn hàng: #${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Khách: ${order.customerName} - ${order.customerPhone}'),
                          const SizedBox(height: 4),
                          Text('Tổng tiền: ${_formatCurrency(order.totalAmount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Chọn trạng thái mới:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: newStatus,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    const Text('Ghi chú / Lý do thay đổi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'VD: Khách đã chuyển cọc, Khách hủy do bận...',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Lưu thay đổi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      String? token = await SessionHelper.token;
      if (token != null) {
        int ret = await OrderRepository.updateStatus(
          order.orderId,
          newStatus,
          reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
          token,
        );
        if (!mounted) return;
        if (ret > 0) {
          showMessage(context, 'Cập nhật trạng thái đơn #${order.orderNumber} thành công!');
          _loadOrders();
        } else {
          showMessage(context, 'Cập nhật trạng thái thất bại', isError: true);
        }
      }
    }
  }

  // 1. XEM CHI TIẾT ĐƠN HÀNG (BOTTOM SHEET)
  void _onViewOrderDetail(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiết đơn #${order.orderNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: order.statusColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(order.statusIcon, size: 14, color: order.statusColor),
                            const SizedBox(width: 4),
                            Text(
                              order.statusText,
                              style: TextStyle(color: order.statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Thông tin khách hàng
                  const Text('THÔNG TIN KHÁCH HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('SĐT: ${order.customerPhone}\nNgày chơi: ${order.playDate}'),
                  ),
                  if (order.note != null && order.note!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.note, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Ghi chú: ${order.note}', style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Danh sách mặt hàng (Sân & Dịch vụ)
                  const SizedBox(height: 8),
                  Text('DANH SÁCH MẶT HÀNG (${order.items.length})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  if (order.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Không có chi tiết mặt hàng'),
                    )
                  else
                    ...order.items.map((item) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.isCourt ? Colors.green.shade100 : Colors.blue.shade100,
                            child: Icon(
                              item.isCourt ? Icons.sports_tennis : Icons.shopping_bag,
                              color: item.isCourt ? Colors.green.shade800 : Colors.blue.shade800,
                              size: 20,
                            ),
                          ),
                          title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item.quantity} ${item.unit} x ${_formatCurrency(item.unitPrice ?? 0)}'),
                          trailing: Text(
                            _formatCurrency(item.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      );
                    }),

                  const Divider(height: 24),

                  // Thanh toán
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tiền cọc:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(_formatCurrency(order.depositAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG TIỀN:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        _formatCurrency(order.totalAmount),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Ngày tạo: ${_formatDateTime(order.createdAt.toLocal())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (order.updatedAt != null)
                    Text('Cập nhật lần cuối: ${_formatDateTime(order.updatedAt!.toLocal())}', style: const TextStyle(fontSize: 12, color: Colors.grey)),

                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _onUpdateStatus(order);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Cập nhật trạng thái đơn này'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 4. Chọn khoảng ngày tùy chỉnh
  void _onPickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      helpText: 'CHỌN KHOẢNG NGÀY ĐẶT CHƠI',
      saveText: 'Áp dụng',
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _datePreset = 'custom';
      });
      _loadOrders();
    }
  }

  void _setDatePreset(String preset) {
    setState(() {
      _datePreset = preset;
      if (preset != 'custom') {
        _selectedDateRange = null;
      }
    });
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách',
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // KHỐI 1: TÌM KIẾM ĐƠN HÀNG (0.25đ)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.red.shade50,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo mã đơn (DH...), tên khách, SĐT...',
                prefixIcon: const Icon(Icons.search, color: Colors.red),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadOrders();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _loadOrders(),
              onChanged: (val) {
                // Tự động tìm khi xóa sạch ô tìm kiếm
                if (val.isEmpty) _loadOrders();
              },
            ),
          ),

          // KHỐI 2: LỌC THEO NGÀY (0.25đ)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.shade50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Ngày: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _datePreset == 'all',
                    onSelected: (_) => _setDatePreset('all'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Hôm nay'),
                    selected: _datePreset == 'today',
                    onSelected: (_) => _setDatePreset('today'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('7 ngày qua'),
                    selected: _datePreset == '7days',
                    onSelected: (_) => _setDatePreset('7days'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month, size: 16),
                    label: Text(
                      _selectedDateRange == null
                          ? 'Tùy chọn...'
                          : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                    ),
                    backgroundColor: _datePreset == 'custom' ? Colors.red.shade100 : null,
                    onPressed: _onPickDateRange,
                  ),
                  if (_datePreset != 'all' || _searchController.text.isNotEmpty || _selectedStatus != 'ALL') ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.filter_alt_off, color: Colors.red, size: 20),
                      tooltip: 'Xóa bộ lọc',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedStatus = 'ALL';
                          _datePreset = 'all';
                          _selectedDateRange = null;
                        });
                        _loadOrders();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // KHỐI 3: LỌC THEO TRẠNG THÁI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text('Tất cả (${_orders.length})'),
                    selected: _selectedStatus == 'ALL',
                    onSelected: (_) {
                      setState(() => _selectedStatus = 'ALL');
                      _loadOrders();
                    },
                  ),
                  const SizedBox(width: 6),
                  ..._statusOptions.map((opt) {
                    bool isSelected = _selectedStatus == opt['code'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(opt['name']!),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedStatus = opt['code']!);
                          _loadOrders();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // KHỐI 4: HIỂN THỊ DANH SÁCH ĐƠN HÀNG (0.25đ)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy đơn hàng nào phù hợp',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedStatus = 'ALL';
                                  _datePreset = 'all';
                                  _selectedDateRange = null;
                                });
                                _loadOrders();
                              },
                              child: const Text('Xem tất cả đơn hàng'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Card: Mã đơn + Trạng thái
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.receipt, color: Colors.blueGrey, size: 20),
                                            const SizedBox(width: 6),
                                            Text(
                                              '#${order.orderNumber}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: order.statusBgColor,
                                            borderRadius: BorderRadius.circular(12),
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
                                    const Divider(height: 16),

                                    // Thông tin khách & Ngày chơi
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${order.customerName} - ${order.customerPhone}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.event, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text('Ngày đặt chơi: ${order.playDate}'),
                                        const Spacer(),
                                        Text(
                                          '${order.itemCount} mục',
                                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Tổng tiền & Tiền cọc
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Cọc: ${_formatCurrency(order.depositAmount)}',
                                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                                          ),
                                          Row(
                                            children: [
                                              const Text('Tổng: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                              Text(
                                                _formatCurrency(order.totalAmount),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.green.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Action buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _onViewOrderDetail(order),
                                          icon: const Icon(Icons.visibility, size: 16),
                                          label: const Text('Chi tiết'),
                                          style: OutlinedButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _onUpdateStatus(order),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Đổi trạng thái'),
                                          style: ElevatedButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            backgroundColor: Colors.blue.shade700,
                                            foregroundColor: Colors.white,
                                          ),
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
          ),
        ],
      ),
    );
  }
}

