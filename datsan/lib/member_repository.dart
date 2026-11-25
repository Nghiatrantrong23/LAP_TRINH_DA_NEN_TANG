import 'api_client.dart';
import 'login.dart';
import 'login_response.dart';
import 'member.dart';

class MemberRepository {
  final ApiClient api;
  MemberRepository(this.api);
  Future<LoginResponse> login(Login model) async => LoginResponse.fromMap(
    await api.call('POST', '/auth/login', body: model.toMap()),
  );
  Future<void> sendVerificationEmail() async {
    await api.call('POST', '/auth/send-verification-email');
  }

  Future<void> verifyEmail(String otp) async {
    await api.call('POST', '/auth/verify-email', body: {'otp': otp});
  }

  Future<void> forgotPassword(String email) async {
    await api.call(
      'POST',
      '/auth/forgot-password',
      body: {'email': email},
      retryAuth: false,
    );
  }

  Future<void> resetPassword(String email, String otp, String password) async {
    await api.call(
      'POST',
      '/auth/reset-password',
      body: {'email': email, 'otp': otp, 'newPassword': password},
      retryAuth: false,
    );
  }

  Future<LoginResponse> externalLogin(String provider) async {
    final slug = provider.toLowerCase();
    return LoginResponse.fromMap(
      await api.call(
        'POST',
        '/auth/external-login',
        body: {
          'provider': provider,
          'email': '$slug@sportbooking.invalid',
          'name': '$provider Demo',
          'providerKey': 'demo-$slug',
        },
        retryAuth: false,
      ),
    );
  }

  Future<Member> register({
    required String email,
    required String password,
    required String givenName,
    required String surname,
    String? phone,
  }) async => Member.fromMap(
    await api.call(
      'POST',
      '/auth/register',
      body: {
        'email': email.trim(),
        'password': password,
        'givenName': givenName.trim(),
        'surname': surname.trim(),
        'phone': phone?.trim(),
      },
    ),
  );
  Future<Member> getMember() async =>
      Member.fromMap(await api.call('GET', '/member/me'));
  Future<Member> updateMember(
    Member current,
    String givenName,
    String surname,
    String phone, {
    bool admin = false,
  }) async => Member.fromMap(
    await api.call(
      'PUT',
      admin ? '/admin/member/${current.id}' : '/member/me',
      body: {
        'givenName': givenName.trim(),
        'surname': surname.trim(),
        'phone': phone.trim(),
        'rowVersion': current.rowVersion,
      },
    ),
  );
  Future<Map<String, dynamic>> getMembers({
    String search = '',
    int pageIndex = 1,
  }) async => await api.call(
    'GET',
    '/admin/member?search=${Uri.encodeQueryComponent(search)}&pageIndex=$pageIndex&pageSize=10',
  );
  Future<Member> setLocked(Member current, bool locked) async => Member.fromMap(
    await api.call(
      'PUT',
      '/admin/member/${current.id}/lock',
      body: {'isLocked': locked, 'rowVersion': current.rowVersion},
    ),
  );
  Future<Member> setRole(Member current, int roleId) async => Member.fromMap(
    await api.call(
      'PUT',
      '/admin/member/${current.id}/role',
      body: {'roleId': roleId, 'rowVersion': current.rowVersion},
    ),
  );
}
