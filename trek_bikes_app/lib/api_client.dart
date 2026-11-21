import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int status;
  final String? code;
  const ApiException(this.message, {this.status = 0, this.code});
  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final http.Client client;
  String? token;
  Future<bool> Function()? refreshSession;
  ApiClient(this.baseUrl, {http.Client? client})
    : client = client ?? http.Client();
  Future<dynamic> call(
    String method,
    String route, {
    Map<String, dynamic>? body,
    bool retryAuth = true,
  }) async {
    final request = http.Request(
      method,
      Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}/api$route'),
    );
    request.headers['content-type'] = 'application/json';
    if (token != null) request.headers['authorization'] = 'Bearer $token';
    if (body != null) request.body = jsonEncode(body);
    late http.Response response;
    try {
      response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 15)),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException('Không kết nối được máy chủ tại $baseUrl.');
    }
    if (response.statusCode == 401 &&
        retryAuth &&
        !['/auth/login', '/auth/register', '/auth/refresh'].contains(route) &&
        refreshSession != null) {
      if (await refreshSession!()) {
        return call(method, route, body: body, retryAuth: false);
      }
    }
    dynamic data;
    try {
      data = response.body.isEmpty
          ? null
          : jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      data = null;
    }
    if (response.statusCode >= 400) {
      var message = data is Map
          ? (data['title'] ?? 'Yêu cầu thất bại.').toString()
          : 'Yêu cầu thất bại (${response.statusCode}).';
      if (data is Map && data['errors'] is Map) {
        message = (data['errors'] as Map).values
            .expand((v) => v is List ? v : [v])
            .join('\n');
      }
      if (response.statusCode == 401) message = 'Email, mật khẩu hoặc phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.';
      if (response.statusCode == 429) {
        message = 'Bạn thao tác quá nhanh. Vui lòng thử lại sau một phút.';
      }
      throw ApiException(
        message,
        status: response.statusCode,
        code: data is Map ? data['code'] : null,
      );
    }
    return data;
  }
}
