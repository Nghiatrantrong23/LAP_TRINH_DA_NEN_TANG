import 'package:flutter/material.dart';
import 'package:trek_bikes_app/helper.dart';
import 'package:trek_bikes_app/invoice.dart';
import 'package:trek_bikes_app/invoice_details_page.dart';
import 'package:trek_bikes_app/invoice_repository.dart';
import 'package:trek_bikes_app/session_helper.dart';
import 'package:trek_bikes_app/status.dart';
import 'package:trek_bikes_app/status_repository.dart';

// Quản lý đơn hàng (Admin)
// 1. Hiển thị danh sách đơn hàng (Bắt buộc - 0.25đ)
// 2. Cập nhật trạng thái đơn hàng (Bắt buộc - 0.50đ)
// 3. Tìm kiếm đơn hàng (Điểm cộng - 0.25đ)
// 4. Lọc đơn hàng theo ngày (Điểm cộng - 0.25đ)
// 5. Kết nối API backend (0.25đ)
class InvoicePage extends StatefulWidget {
  final String title;
  const InvoicePage({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<Invoice> _invoices = [];
  List<Status> _status = [];
  bool _isLoading = true;

  // 3. Tìm kiếm đơn hàng
  final TextEditingController _searchController = TextEditingController();

  // 4. Lọc đơn hàng
  int? _selectedStatusId;
  String _datePreset = 'all'; // all, today, 7days, custom
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadStatuses();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadStatuses() async {
    try {
      var data = await StatusRepository.getStatuses();
      if (mounted) {
        setState(() {
          _status = data;
        });
      }
    } catch (_) {}
  }

  void _loadInvoices() async {
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

      var data = await InvoiceRepository.getInvoices(
        token,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        statusId: _selectedStatusId,
        fromDate: fromDate,
        toDate: toDate,
      );

      if (mounted) {
        setState(() {
          _invoices = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. CẬP NHẬT TRẠNG THÁI ĐƠN HÀNG (0.50đ)
  void _onUpdateStatus(Invoice item) async {
    int selectedStatus = item.statusId;

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
                  Text('Update Order #${item.id}'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: ${item.memberId ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Date: ${_formatDate(item.dated)}'),
                  const SizedBox(height: 16),
                  const Text('Select New Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _status.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.name),
                      );
                    }).toList(),
                    onChanged: (int? val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedStatus = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
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
        int ret = await InvoiceRepository.updateStatus(item.id, selectedStatus, token);
        if (!mounted) return;
        if (ret > 0) {
          showMessage(context, 'Updated status for Order #${item.id} successfully!');
          _loadInvoices();
        } else {
          showMessage(context, 'Update status failed');
        }
      }
    }
  }

  void _onDetails(Invoice obj) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsPage(title: 'Order Details #${obj.id}', initialInvoice: obj),
      ),
    );
  }

  void _onPickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      helpText: 'SELECT DATE RANGE',
      saveText: 'Apply',
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _datePreset = 'custom';
      });
      _loadInvoices();
    }
  }

  void _setDatePreset(String preset) {
    setState(() {
      _datePreset = preset;
      if (preset != 'custom') {
        _selectedDateRange = null;
      }
    });
    _loadInvoices();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatShortDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatCurrency(num amount) {
    String str = amount.toStringAsFixed(2);
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '\$$result';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: Column(
        children: [
          // KHỐI 1: TÌM KIẾM ĐƠN HÀNG (0.25đ)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            color: Colors.grey.shade100,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Order ID or Customer...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadInvoices();
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
              onSubmitted: (_) => _loadInvoices(),
              onChanged: (val) {
                if (val.isEmpty) _loadInvoices();
              },
            ),
          ),

          // KHỐI 2: LỌC THEO NGÀY (0.25đ)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Date: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _datePreset == 'all',
                    onSelected: (_) => _setDatePreset('all'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Today'),
                    selected: _datePreset == 'today',
                    onSelected: (_) => _setDatePreset('today'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Last 7 Days'),
                    selected: _datePreset == '7days',
                    onSelected: (_) => _setDatePreset('7days'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month, size: 16),
                    label: Text(
                      _selectedDateRange == null
                          ? 'Custom Range...'
                          : '${_formatShortDate(_selectedDateRange!.start)} - ${_formatShortDate(_selectedDateRange!.end)}',
                    ),
                    backgroundColor: _datePreset == 'custom' ? Colors.blue.shade100 : null,
                    onPressed: _onPickDateRange,
                  ),
                  if (_datePreset != 'all' || _selectedStatusId != null || _searchController.text.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.filter_alt_off, color: Colors.red, size: 20),
                      tooltip: 'Clear filters',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedStatusId = null;
                          _datePreset = 'all';
                          _selectedDateRange = null;
                        });
                        _loadInvoices();
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
                    label: Text('All (${_invoices.length})'),
                    selected: _selectedStatusId == null,
                    onSelected: (_) {
                      setState(() => _selectedStatusId = null);
                      _loadInvoices();
                    },
                  ),
                  const SizedBox(width: 6),
                  ..._status.map((st) {
                    bool isSelected = _selectedStatusId == st.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(st.name),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedStatusId = st.id);
                          _loadInvoices();
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
                : _invoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No orders found', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedStatusId = null;
                                  _datePreset = 'all';
                                  _selectedDateRange = null;
                                });
                                _loadInvoices();
                              },
                              child: const Text('Show all orders'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadInvoices(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _invoices.length,
                          itemBuilder: (context, index) {
                            final item = _invoices[index];
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
                                              'Order #${item.id}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.statusBgColor,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: item.statusColor),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(item.statusIcon, size: 14, color: item.statusColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.displayStatusName,
                                                style: TextStyle(
                                                  color: item.statusColor,
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

                                    // Customer & Date
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Customer: ${item.memberId ?? "N/A"}',
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text('Date: ${_formatDate(item.dated)}'),
                                        const Spacer(),
                                        if (item.details.isNotEmpty)
                                          Text(
                                            '${item.details.length} item(s)',
                                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                                          ),
                                      ],
                                    ),
                                    if (item.totalAmount > 0) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text(
                                            _formatCurrency(item.totalAmount),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 10),

                                    // Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _onDetails(item),
                                          icon: const Icon(Icons.visibility, size: 16),
                                          label: const Text('Details'),
                                          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () => _onUpdateStatus(item),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('Update Status'),
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
