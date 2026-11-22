import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sport_booking_app/models/member.dart';

class MemberRepository {
  static String get baseUrl => "${dotenv.env['API_URL'] ?? 'http://localhost:5109'}/api/member";
  static String get authUrl => "${dotenv.env['API_URL'] ?? 'http://localhost:5109'}/api/auth";

  // Lấy thông tin cá nhân (Profile)
  static Future<Member?> getProfile(String token) async {
    try {
      var rs = await http.get(
        Uri.parse('$authUrl/profile'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
      );

      if (rs.statusCode == 200) {
        return Member.fromMap(jsonDecode(rs.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Cập nhật thông tin cá nhân
  static Future<int> updateProfile({
    required String givenName,
    String? surname,
    String? phone,
    required String token,
  }) async {
    try {
      var rs = await http.put(
        Uri.parse('$authUrl/profile'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({'givenName': givenName, 'surname': surname, 'phone': phone}),
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

  // Quản lý Member (Admin) - Lấy toàn bộ danh sách Member
  static Future<List<Member>> getMembers(String token) async {
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
        return data.map((p) => Member.fromMap(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Khóa / Mở khóa tài khoản Member (Admin)
  static Future<int> toggleStatus(String memberId, String token) async {
    try {
      var rs = await http.put(
        Uri.parse('$baseUrl/toggle-status/$memberId'),
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

  // Phân quyền Role cho Member (Admin)
  static Future<int> changeRole(String memberId, int roleId, String token) async {
    try {
      var rs = await http.put(
        Uri.parse('$baseUrl/change-role'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({'memberId': memberId, 'roleId': roleId}),
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

