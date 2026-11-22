import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> save({
    required String email,
    required String token,
    required String role,
    String? refreshToken,
    String? fullName,
    String? memberId,
  }) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'role', value: role);
    if (refreshToken != null) {
      await _storage.write(key: 'refreshToken', value: refreshToken);
    }
    if (fullName != null) {
      await _storage.write(key: 'fullName', value: fullName);
    }
    if (memberId != null) {
      await _storage.write(key: 'memberId', value: memberId);
    }
  }

  static Future<void> delete() async {
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'role');
    await _storage.delete(key: 'fullName');
    await _storage.delete(key: 'memberId');
  }

  static Future<String?> get email async => await _storage.read(key: 'email');
  static Future<String?> get token async => await _storage.read(key: 'token');
  static Future<String?> get refreshToken async => await _storage.read(key: 'refreshToken');
  static Future<String?> get role async => await _storage.read(key: 'role');
  static Future<String?> get fullName async => await _storage.read(key: 'fullName');
  static Future<String?> get memberId async => await _storage.read(key: 'memberId');

  static Future<bool> get isAdmin async {
    String? r = await role;
    return r != null && r.toLowerCase() == 'admin';
  }

  static Future<bool> get isLoggedIn async {
    String? t = await token;
    return t != null && t.isNotEmpty;
  }
}
