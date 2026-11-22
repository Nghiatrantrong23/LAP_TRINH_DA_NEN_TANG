import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/repositories/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  final String title;
  const RegisterPage({super.key, required this.title});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _givenNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  void _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;
    String givenName = _givenNameController.text.trim();
    String surname = _surnameController.text.trim();
    String phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty || givenName.isEmpty) {
      setState(() => _error = 'Vui lòng điền các trường bắt buộc (*)');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    var ret = await AuthRepository.register(
      email: email,
      password: password,
      givenName: givenName,
      surname: surname,
      phone: phone,
    );

    setState(() => _isLoading = false);

    if (ret['code'] > 0) {
      if (!mounted) return;
      showMessage(context, 'Đăng ký thành công! Hãy nhập mã OTP để kích hoạt tài khoản.');
      // Chuyển sang trang xác thực mã OTP gửi về Email
      Navigator.pushReplacementNamed(context, '/verify-email', arguments: email);
    } else {
      setState(() => _error = ret['message']);
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
            const Text(
              'TẠO TÀI KHOẢN MỚI',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (*)',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _givenNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên (*)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu (*)',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu (*)',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            if (_error != null && _error!.isNotEmpty) ...[
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ],
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _register,
              icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.how_to_reg),
              label: const Text('ĐĂNG KÝ NGAY', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

