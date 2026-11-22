import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:trek_bikes_app/invoice.dart';

class InvoiceRepository {
  static String get baseUrl => "${dotenv.env['API_URL'] ?? 'http://localhost:5283'}/api/invoice";

  static Future<int> add(Invoice obj, String token) async {
    var rs = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'content-type': "application/json",
        "authorization": 'Bearer $token',
      },
      body: jsonEncode(obj.toMap()),
    );
    if (rs.statusCode == 200) {
      return int.parse(rs.body);
    }
    return -2;
  }

  // 2. Cập nhật trạng thái đơn hàng (Bắt buộc - 0.50đ)
  static Future<int> updateStatus(int id, int statusId, String token) async {
    var rs = await http.put(
      Uri.parse('$baseUrl/status?id=$id&statusId=$statusId'),
      headers: {
        'content-type': "application/json",
        'authorization': 'Bearer $token',
      },
    );
    if (rs.statusCode == 200) {
      return int.tryParse(rs.body) ?? 1;
    }
    return -2;
  }

  // Xem chi tiết đơn hàng
  static Future<Invoice> getInvoice(int id, String token) async {
    var rs = await http.get(
      Uri.parse('$baseUrl/details/$id'),
      headers: {
        'content-type': "application/json",
        "authorization": 'Bearer $token',
      },
    );
    if (rs.statusCode == 200) {
      dynamic data = jsonDecode(rs.body);
      return Invoice.fromMap(data);
    }
    throw Exception('Not found $baseUrl/details/$id');
  }

  // 1. Hiển thị danh sách đơn hàng (Bắt buộc - 0.25đ)
  // 3. Tìm kiếm đơn hàng (Điểm cộng - 0.25đ)
  // 4. Lọc đơn hàng theo ngày (Điểm cộng - 0.25đ)
  static Future<List<Invoice>> getInvoices(
    String token, {
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
    int? statusId,
  }) async {
    try {
      Map<String, String> queryParams = {};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (statusId != null && statusId > 0) {
        queryParams['statusId'] = statusId.toString();
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
          'content-type': "application/json",
          "authorization": 'Bearer $token',
        },
      );
      if (rs.statusCode == 200) {
        List<dynamic> data = jsonDecode(rs.body);
        return data.map((p) => Invoice.fromMap(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
