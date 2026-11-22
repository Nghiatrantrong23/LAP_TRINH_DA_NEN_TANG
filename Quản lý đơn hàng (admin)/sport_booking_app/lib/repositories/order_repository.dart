import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sport_booking_app/models/order_model.dart';

class OrderRepository {
  static String get baseUrl => "${dotenv.env['API_URL'] ?? 'http://localhost:5109'}/api/order";

  // Lấy danh sách đơn hàng (hỗ trợ tìm kiếm, lọc theo trạng thái và ngày)
  static Future<List<OrderModel>> getOrders(
    String token, {
    String? search,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status.isNotEmpty && status != 'ALL') {
        queryParams['status'] = status;
      }
      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }
      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }

      var uri = Uri.parse(baseUrl).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      var rs = await http.get(
        uri,
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
      );

      if (rs.statusCode == 200) {
        List<dynamic> data = jsonDecode(rs.body);
        return data.map((e) => OrderModel.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Xem chi tiết đơn hàng
  static Future<OrderModel?> getOrderById(String orderId, String token) async {
    try {
      var rs = await http.get(
        Uri.parse('$baseUrl/$orderId'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
      );

      if (rs.statusCode == 200) {
        return OrderModel.fromMap(jsonDecode(rs.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cập nhật trạng thái đơn hàng (ChoCoc, DaXacNhan, DangChoi, HoanThanh, DaHuy)
  static Future<int> updateStatus(
    String orderId,
    String newStatus,
    String? reason,
    String token,
  ) async {
    try {
      var rs = await http.put(
        Uri.parse('$baseUrl/$orderId/status'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'trangThai': newStatus,
          'lyDo': reason,
        }),
      );

      if (rs.statusCode == 200) {
        var data = jsonDecode(rs.body);
        return data['code'] ?? 1;
      }
      return -2;
    } catch (e) {
      return -2;
    }
  }
}

