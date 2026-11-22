import 'api_client.dart';
import 'order_model.dart';

class OrderRepository {
  final ApiClient api;
  OrderRepository(this.api);

  Future<List<OrderModel>> getOrders({
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String>[];
    if (search != null && search.trim().isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search.trim())}');
    }
    if (status != null && status.isNotEmpty && status != 'ALL') {
      queryParams.add('status=${Uri.encodeComponent(status)}');
    }
    if (fromDate != null) {
      queryParams.add('fromDate=${fromDate.toIso8601String()}');
    }
    if (toDate != null) {
      queryParams.add('toDate=${toDate.toIso8601String()}');
    }

    final queryString = queryParams.isEmpty ? '' : '?${queryParams.join('&')}';
    final response = await api.call('GET', '/admin/order$queryString');

    if (response is List) {
      return response
          .map((item) => OrderModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<OrderModel?> getOrder(String id) async {
    final response = await api.call('GET', '/admin/order/$id');
    if (response is Map<String, dynamic>) {
      return OrderModel.fromMap(response);
    }
    return null;
  }

  Future<dynamic> updateStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    return await api.call('PUT', '/admin/order/$id/status', body: {
      'trangThai': status,
      'lyDo': reason ?? '',
    });
  }

  Future<List<Map<String, String>>> getStatuses() async {
    final response = await api.call('GET', '/admin/order/statuses');
    if (response is List) {
      return response.map((e) {
        final m = e as Map<String, dynamic>;
        return {
          'code': m['code']?.toString() ?? '',
          'name': m['name']?.toString() ?? '',
          'color': m['color']?.toString() ?? '',
        };
      }).toList();
    }
    return [
      {'code': 'ChoCoc', 'name': 'Chờ cọc'},
      {'code': 'DaXacNhan', 'name': 'Đã xác nhận'},
      {'code': 'DangChoi', 'name': 'Đang chơi'},
      {'code': 'HoanThanh', 'name': 'Hoàn thành'},
      {'code': 'DaHuy', 'name': 'Đã hủy'},
    ];
  }
}
