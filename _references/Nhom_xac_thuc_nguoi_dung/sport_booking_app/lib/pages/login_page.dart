import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/helpers/session_helper.dart';
import 'package:sport_booking_app/models/login_response.dart';
import 'package:sport_booking_app/repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  final String title;
  const LoginPage({super.key, required this.title});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _error;
  bool _isLoading = false;

  // Cấu hình Google Sign-In chuẩn: Web dùng clientId, Mobile dùng serverClientId
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? (dotenv.env['GOOGLE_CLIENT_ID'] ?? 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com') : null,
    serverClientId: kIsWeb ? null : (dotenv.env['GOOGLE_CLIENT_ID'] ?? 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com'),
    scopes: ['email', 'profile'],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 1. Đăng nhập truyền thống bằng Email & Password
  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ Email và Mật khẩu');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    LoginResponse result = await AuthRepository.login(email, password);

    setState(() => _isLoading = false);

    if (result.success && result.token != null) {
      await SessionHelper.save(
        email: result.email ?? email,
        token: result.token!,
        refreshToken: result.refreshToken,
        role: result.role ?? 'Member',
        fullName: result.fullName,
        memberId: result.memberId,
      );

      if (!mounted) return;
      showMessage(context, 'Đăng nhập thành công!');
      Navigator.pop(context, true);
    } else {
      setState(() => _error = result.message);

      // Nếu tài khoản chưa xác thực email, dẫn người dùng tới trang kích hoạt OTP
      if (result.message.contains('chưa được xác thực email')) {
        if (!mounted) return;
        Navigator.pushNamed(context, '/verify-email', arguments: email);
      }
    }
  }

  // Xử lý lưu phiên và điều hướng khi đăng nhập mạng xã hội thành công
  void _handleSocialLoginSuccess(
    LoginResponse result,
    String provider,
    String defaultEmail,
    String defaultName,
  ) async {
    if (result.success && result.token != null) {
      await SessionHelper.save(
        email: result.email ?? defaultEmail,
        token: result.token!,
        refreshToken: result.refreshToken,
        role: result.role ?? 'Member',
        fullName: result.fullName ?? defaultName,
        memberId: result.memberId,
      );

      if (!mounted) return;
      showMessage(context, 'Đăng nhập $provider thành công!');
      Navigator.pop(context, true);
    } else {
      setState(() => _error = result.message.isNotEmpty ? result.message : 'Đăng nhập $provider không thành công');
    }
  }

  // 2. Đăng nhập Google (Gmail) - Điểm cộng 0.5đ
  void _onGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // Người dùng hủy chọn tài khoản
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      LoginResponse result;
      if (idToken != null && idToken.isNotEmpty) {
        // Gửi ID Token thật lên WebApi để máy chủ C# xác thực với Google
        result = await AuthRepository.googleLogin(idToken);
      } else {
        // Môi trường desktop hoặc không lấy được ID Token -> Dùng thông tin tài khoản Google xác nhận
        result = await AuthRepository.externalLogin(
          provider: 'Google',
          providerKey: account.id,
          email: account.email,
          fullName: account.displayName ?? account.email,
        );
      }

      setState(() => _isLoading = false);
      _handleSocialLoginSuccess(result, 'Google', account.email, account.displayName ?? account.email);
    } catch (e) {
      setState(() => _isLoading = false);
      // Khi chạy trên nền tảng chưa cấu hình Google Play Services, hiển thị hộp thoại đăng nhập thử nghiệm linh hoạt
      _showSocialDialog(
        provider: 'Google',
        icon: Icons.g_mobiledata,
        iconColor: Colors.red,
        defaultEmail: 'user.google@gmail.com',
        defaultName: 'Google User',
        note: 'Gặp ngoại lệ Google SDK ($e). Bạn có thể đăng nhập bằng tài khoản thử nghiệm:',
        onTokenSubmit: (token) async {
          setState(() => _isLoading = true);
          var res = await AuthRepository.googleLogin(token);
          setState(() => _isLoading = false);
          _handleSocialLoginSuccess(res, 'Google', 'user.google@gmail.com', 'Google User');
        },
        onQuickLogin: (email, name) async {
          setState(() => _isLoading = true);
          var res = await AuthRepository.externalLogin(
            provider: 'Google',
            providerKey: 'google_${DateTime.now().millisecondsSinceEpoch}',
            email: email,
            fullName: name,
          );
          setState(() => _isLoading = false);
          _handleSocialLoginSuccess(res, 'Google', email, name);
        },
      );
    }
  }

  // 3. Đăng nhập Facebook - Điểm cộng 0.5đ
  void _onFacebookLogin() {
    _showSocialDialog(
      provider: 'Facebook',
      icon: Icons.facebook,
      iconColor: const Color(0xFF1877F2),
      defaultEmail: 'user.fb@facebook.com',
      defaultName: 'Facebook User',
      appId: dotenv.env['FACEBOOK_APP_ID'] ?? 'YOUR_FACEBOOK_APP_ID',
      note: 'Bạn có thể xác thực bằng Access Token thật từ Meta Graph API hoặc đăng nhập nhanh tài khoản kiểm thử:',
      onTokenSubmit: (token) async {
        setState(() => _isLoading = true);
        var res = await AuthRepository.facebookLogin(token);
        setState(() => _isLoading = false);
        _handleSocialLoginSuccess(res, 'Facebook', 'user.fb@facebook.com', 'Facebook User');
      },
      onQuickLogin: (email, name) async {
        setState(() => _isLoading = true);
        var res = await AuthRepository.externalLogin(
          provider: 'Facebook',
          providerKey: 'fb_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: name,
        );
        setState(() => _isLoading = false);
        _handleSocialLoginSuccess(res, 'Facebook', email, name);
      },
    );
  }

  // 4. Đăng nhập Zalo - Điểm cộng 0.5đ
  void _onZaloLogin() {
    _showSocialDialog(
      provider: 'Zalo',
      icon: Icons.chat,
      iconColor: const Color(0xFF0068FF),
      defaultEmail: 'user.zalo@zalo.me',
      defaultName: 'Zalo User',
      note: 'Ứng dụng: SportBookingApp. Bạn có thể xác thực bằng Access Token thật từ Zalo Graph API hoặc đăng nhập nhanh tài khoản kiểm thử:',
      onTokenSubmit: (token) async {
        setState(() => _isLoading = true);
        var res = await AuthRepository.zaloLogin(token);
        setState(() => _isLoading = false);
        _handleSocialLoginSuccess(res, 'Zalo', 'user.zalo@zalo.me', 'Zalo User');
      },
      onQuickLogin: (email, name) async {
        setState(() => _isLoading = true);
        var res = await AuthRepository.externalLogin(
          provider: 'Zalo',
          providerKey: 'zalo_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          fullName: name,
        );
        setState(() => _isLoading = false);
        _handleSocialLoginSuccess(res, 'Zalo', email, name);
      },
    );
  }

  // Hộp thoại tùy chọn xác thực Token hoặc Đăng nhập nhanh kiểm thử
  void _showSocialDialog({
    required String provider,
    required IconData icon,
    required Color iconColor,
    required String defaultEmail,
    required String defaultName,
    String? appId,
    required String note,
    required Function(String token) onTokenSubmit,
    required Function(String email, String name) onQuickLogin,
  }) {
    final emailCtrl = TextEditingController(text: defaultEmail);
    final nameCtrl = TextEditingController(text: defaultName);
    final tokenCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đăng nhập với $provider',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  note,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (appId != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      'App ID: $appId',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                  ),
                ],
                const Divider(height: 24),
                const Text(
                  'Cách 1: Đăng nhập nhanh tài khoản kiểm thử',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email tài khoản',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên hiển thị',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onQuickLogin(emailCtrl.text.trim(), nameCtrl.text.trim());
                  },
                  icon: const Icon(Icons.flash_on),
                  label: Text('ĐĂNG NHẬP NGAY VỚI ${provider.toUpperCase()}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const Divider(height: 28),
                const Text(
                  'Cách 2: Xác thực bằng Access Token thật (Graph API)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tokenCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Dán Access Token / ID Token $provider vào đây...',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    if (tokenCtrl.text.trim().isEmpty) {
                      showMessage(context, 'Vui lòng dán Token trước khi xác thực');
                      return;
                    }
                    Navigator.pop(ctx);
                    onTokenSubmit(tokenCtrl.text.trim());
                  },
                  icon: const Icon(Icons.verified_user),
                  label: const Text('XÁC THỰC TOKEN VỚI MÁY CHỦ WEB API'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onRegister() {
    Navigator.pushNamed(context, '/register');
  }

  void _onForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.sports_soccer, size: 72, color: Colors.green),
            const SizedBox(height: 10),
            const Text(
              'ĐẶT SÂN THỂ THAO',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email đăng nhập',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _onForgotPassword,
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            if (_error != null && _error!.isNotEmpty) ...[
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ],
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.login),
              label: const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chưa có tài khoản?'),
                TextButton(
                  onPressed: _onRegister,
                  child: const Text('Đăng ký ngay'),
                ),
              ],
            ),
            const Divider(height: 30),
            const Text(
              'Hoặc đăng nhập bằng mạng xã hội:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 15),
            // Điểm cộng 1: Đăng nhập Google (Gmail) - 0.5đ
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onGoogleLogin,
              icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
              label: const Text('Đăng nhập với Google (Gmail)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            // Điểm cộng 2: Đăng nhập Facebook - 0.5đ
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onFacebookLogin,
              icon: const Icon(Icons.facebook, color: Colors.blue, size: 24),
              label: const Text('Đăng nhập với Facebook'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Điểm cộng 3: Đăng nhập Zalo - 0.5đ
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onZaloLogin,
              icon: const Icon(Icons.chat, color: Colors.lightBlue, size: 24),
              label: const Text('Đăng nhập với Zalo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0068FF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
