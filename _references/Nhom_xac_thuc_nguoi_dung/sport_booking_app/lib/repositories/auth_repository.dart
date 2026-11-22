import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sport_booking_app/models/login_response.dart';

class AuthRepository {
  static String get baseUrl => "${dotenv.env['API_URL'] ?? 'http://localhost:5109'}/api/auth";

  // 1. Đăng ký người dùng
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String givenName,
    String? surname,
    String? phone,
  }) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'givenName': givenName,
          'surname': surname,
          'phone': phone,
        }),
      );

      var data = jsonDecode(rs.body);
      return {'code': data['code'] ?? (rs.statusCode == 200 ? 1 : -2), 'message': data['message'] ?? ''};
    } catch (e) {
      return {'code': -2, 'message': 'Lỗi kết nối máy chủ: $e'};
    }
  }

  // 2. Xác thực OTP email
  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      var data = jsonDecode(rs.body);
      return {'code': data['code'] ?? (rs.statusCode == 200 ? 1 : -2), 'message': data['message'] ?? ''};
    } catch (e) {
      return {'code': -2, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Gửi lại mã OTP
  static Future<Map<String, dynamic>> resendCode(String email) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/resend-code'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(email),
      );

      var data = jsonDecode(rs.body);
      return {'code': data['code'] ?? (rs.statusCode == 200 ? 1 : -2), 'message': data['message'] ?? ''};
    } catch (e) {
      return {'code': -2, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // 3. Đăng nhập
  static Future<LoginResponse> login(String email, String password) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      var data = jsonDecode(rs.body);
      return LoginResponse.fromMap(data);
    } catch (e) {
      return LoginResponse(success: false, message: 'Lỗi kết nối: $e');
    }
  }

  // 4.1. Đăng nhập Google qua ID Token (Điểm cộng 0.5đ)
  static Future<LoginResponse> googleLogin(String idToken) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/google-login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      var data = jsonDecode(rs.body);
      return LoginResponse.fromMap(data);
    } catch (e) {
      return LoginResponse(success: false, message: 'Lỗi đăng nhập Google: $e');
    }
  }

  // 4.2. Đăng nhập Facebook qua Access Token (Điểm cộng 0.5đ)
  static Future<LoginResponse> facebookLogin(String accessToken) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/facebook-login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'token': accessToken}),
      );

      var data = jsonDecode(rs.body);
      return LoginResponse.fromMap(data);
    } catch (e) {
      return LoginResponse(success: false, message: 'Lỗi đăng nhập Facebook: $e');
    }
  }

  // 4.3. Đăng nhập Zalo qua Access Token (Điểm cộng 0.5đ)
  static Future<LoginResponse> zaloLogin(String accessToken) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/zalo-login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'token': accessToken}),
      );

      var data = jsonDecode(rs.body);
      return LoginResponse.fromMap(data);
    } catch (e) {
      return LoginResponse(success: false, message: 'Lỗi đăng nhập Zalo: $e');
    }
  }

  // 4.4. Đăng nhập qua mạng xã hội (Gmail, Facebook, Zalo) - Trực tiếp hoặc Mock
  static Future<LoginResponse> externalLogin({
    required String provider,
    required String providerKey,
    required String email,
    required String fullName,
  }) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/external-login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'provider': provider,
          'providerKey': providerKey,
          'email': email,
          'fullName': fullName,
        }),
      );

      var data = jsonDecode(rs.body);
      return LoginResponse.fromMap(data);
    } catch (e) {
      return LoginResponse(success: false, message: 'Lỗi đăng nhập $provider: $e');
    }
  }

  // 5. Quên mật khẩu
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      var data = jsonDecode(rs.body);
      return {'code': data['code'] ?? (rs.statusCode == 200 ? 1 : -2), 'message': data['message'] ?? ''};
    } catch (e) {
      return {'code': -2, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Đặt lại mật khẩu với OTP
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
      );

      var data = jsonDecode(rs.body);
      return {'code': data['code'] ?? (rs.statusCode == 200 ? 1 : -2), 'message': data['message'] ?? ''};
    } catch (e) {
      return {'code': -2, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // 6. Đổi mật khẩu
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      var rs = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer $token',
        },
        body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
      );

      var data = jsonDecode(rs.body);
      return {'code': data['code'] ?? (rs.statusCode == 200 ? 1 : -2), 'message': data['message'] ?? ''};
    } catch (e) {
      return {'code': -2, 'message': 'Lỗi kết nối: $e'};
    }
  }
}

