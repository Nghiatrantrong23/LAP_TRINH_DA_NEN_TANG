import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'login.dart';
import 'login_response.dart';
import 'member.dart';
import 'member_repository.dart';

class SessionHelper extends ChangeNotifier {
  final ApiClient api;
  final FlutterSecureStorage storage;
  late final MemberRepository repository;
  Member? member;
  bool ready = false;
  String? startupError;
  Future<bool>? _refreshing;
  SessionHelper(this.api, {FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage() {
    repository = MemberRepository(api);
    api.refreshSession = refresh;
  }
  Future<void> restore() async {
    try {
      api.token = await storage.read(key: 'sb2_access');
      if (api.token != null) member = await repository.getMember();
    } on ApiException catch (e) {
      startupError = e.message;
      if (e.status == 401 || e.status == 403) await clear();
    } catch (_) {
      startupError = 'Không đọc được phiên đăng nhập. Vui lòng đăng nhập lại.';
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  Future<void> _save(LoginResponse result) async {
    await storage.write(key: 'sb2_access', value: result.token);
    await storage.write(key: 'sb2_refresh', value: result.refreshToken);
    api.token = result.token;
    member = result.member;
    startupError = null;
    notifyListeners();
  }

  Future<void> login(String email, String password) async =>
      _save(await repository.login(Login(email: email, password: password)));
  Future<bool> refresh() async {
    if (_refreshing != null) return _refreshing!;
    final operation = _rotate();
    _refreshing = operation;
    try {
      return await operation;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _rotate() async {
    final refresh = await storage.read(key: 'sb2_refresh');
    if (refresh == null) {
      await clear();
      return false;
    }
    try {
      await _save(
        LoginResponse.fromMap(
          await api.call(
            'POST',
            '/auth/refresh',
            body: {'refreshToken': refresh},
            retryAuth: false,
          ),
        ),
      );
      return true;
    } on ApiException catch (e) {
      if (e.status == 401 || e.status == 403) {
        await clear();
        return false;
      }
      rethrow;
    }
  }

  Future<void> clear() async {
    await storage.delete(key: 'sb2_access');
    await storage.delete(key: 'sb2_refresh');
    api.token = null;
    member = null;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.call('POST', '/auth/logout');
    } finally {
      await clear();
    }
  }

  Future<void> changePassword(String current, String next) async {
    await api.call(
      'PUT',
      '/auth/password',
      body: {'currentPassword': current, 'newPassword': next},
    );
    await clear();
  }

  void setMember(Member next) {
    member = next;
    notifyListeners();
  }
}
