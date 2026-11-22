import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sport_booking_app/models/role.dart';

class RoleRepository {
  static String get baseUrl => "${dotenv.env['API_URL'] ?? 'http://localhost:5109'}/api/role";

  // Lấy danh sách Role
  static Future<List<Role>> getRoles(String token) async {
    try {
      var rs = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
      );

      if (rs.statusCode == 200) {
        List<dynamic> data = jsonDecode(rs.body);
        return data.map((p) => Role.fromMap(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Thêm Role mới (Admin)
  static Future<int> add(Role obj, String token) async {
    try {
      var rs = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode(obj.toMap()),
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

  // Cập nhật Role (Admin)
  static Future<int> update(Role obj, String token) async {
    try {
      var rs = await http.put(
        Uri.parse(baseUrl),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode(obj.toMap()),
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

  // Xóa Role (Admin)
  static Future<int> delete(int roleId, String token) async {
    try {
      var rs = await http.delete(
        Uri.parse('$baseUrl/$roleId'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
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

