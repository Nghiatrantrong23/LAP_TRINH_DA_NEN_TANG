import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/repositories/auth_repository.dart';

// Màn hình Quên mật khẩu (0.5 điểm cộng)
class ForgotPasswordPage extends StatefulWidget {
  final String title;
  const ForgotPasswordPage({super.key, required this.title});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // Bước 1: Gửi email; Bước 2: Nhập OTP và đặt mật khẩu mới
  String? _message;
  bool _isLoading = false;

  void _onSendOtp() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Vui lòng nhập email');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    var ret = await AuthRepository.forgotPassword(email);
    setState(() => _isLoading = false);

    if (ret['code'] > 0) {
      if (!mounted) return;
      showMessage(context, 'Mã OTP đã được gửi đến email của bạn!');
      setState(() => _step = 2);
    } else {
      setState(() => _message = ret['message']);
    }
  }

  void _onResetPassword() async {
    String email = _emailController.text.trim();
    String code = _otpController.text.trim();
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty || newPassword.isEmpty) {
      setState(() => _message = 'Vui lòng điền đầy đủ mã OTP và mật khẩu mới');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _message = 'Mật khẩu xác nhận không trùng khớp');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    var ret = await AuthRepository.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    setState(() => _isLoading = false);

    if (ret['code'] > 0) {
      if (!mounted) return;
      showMessage(context, 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập.');
      Navigator.pop(context);
    } else {
      setState(() => _message = ret['message']);
    }
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
            const Icon(Icons.lock_reset, size: 64, color: Colors.orange),
            const SizedBox(height: 15),
            Text(
              _step == 1
                  ? 'Bước 1: Nhập email đã đăng ký để nhận mã OTP'
                  : 'Bước 2: Nhập mã OTP và thiết lập mật khẩu mới',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (_step == 1) ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email tài khoản',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onSendOtp,
                icon: const Icon(Icons.send),
                label: const Text('GỬI MÃ XÁC THỰC OTP'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Mã OTP từ email (6 số)',
                  prefixIcon: Icon(Icons.security),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onResetPassword,
                icon: const Icon(Icons.check_circle),
                label: const Text('ĐẶT LẠI MẬT KHẨU'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Quay lại bước 1'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 15),
              Text(_message!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}

