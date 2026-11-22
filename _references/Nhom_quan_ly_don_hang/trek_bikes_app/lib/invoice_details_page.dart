import 'package:flutter/material.dart';
import 'package:trek_bikes_app/invoice.dart';
import 'package:trek_bikes_app/invoice_repository.dart';
import 'package:trek_bikes_app/session_helper.dart';

class InvoiceDetailsPage extends StatefulWidget {
  final String title;
  final Invoice? initialInvoice;

  const InvoiceDetailsPage({
    super.key,
    required this.title,
    this.initialInvoice,
  });

  @override
  State<StatefulWidget> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  Invoice? _invoice;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialInvoice != null) {
      _invoice = widget.initialInvoice;
      _isLoading = false;
      _fetchFullDetails(widget.initialInvoice!.id);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_invoice == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _loadInvoice(args);
      }
    }
  }

  void _loadInvoice(int id) async {
    String? token = await SessionHelper.token;
    if (token != null) {
      try {
        var data = await InvoiceRepository.getInvoice(id, token);
        if (mounted) {
          setState(() {
            _invoice = data;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _fetchFullDetails(int id) async {
    String? token = await SessionHelper.token;
    if (token != null) {
      try {
        var data = await InvoiceRepository.getInvoice(id, token);
        if (mounted) {
          setState(() {
            _invoice = data;
          });
        }
      } catch (_) {}
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoice == null
              ? const Center(child: Text('Order data not found'))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Order Summary Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${_invoice!.id}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _invoice!.statusBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _invoice!.statusColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_invoice!.statusIcon, size: 14, color: _invoice!.statusColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _invoice!.displayStatusName,
                                        style: TextStyle(
                                          color: _invoice!.statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text('Customer: ${_invoice!.memberId ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Date Created: ${_formatDate(_invoice!.dated)}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Items
                    const Text('ORDER ITEMS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    if (_invoice!.details.isEmpty)
                      Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No item breakdown available for this order',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      ..._invoice!.details.map((item) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.pedal_bike),
                            ),
                            title: Text(
                              item.bikeName ?? 'Bike #${item.bikeId}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Qty: ${item.quantity} x ${_formatCurrency(item.price)}'),
                            trailing: Text(
                              _formatCurrency(item.lineTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            _formatCurrency(_invoice!.totalAmount),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
    );
  }
}
