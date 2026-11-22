import 'package:flutter/material.dart';
import 'package:sport_booking_app/helpers/helper.dart';
import 'package:sport_booking_app/helpers/session_helper.dart';
import 'package:sport_booking_app/repositories/auth_repository.dart';

// Đổi mật khẩu (0.25đ bắt buộc)
class ChangePasswordPage extends StatefulWidget {
  final String title;
  const ChangePasswordPage({super.key, required this.title});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _message;
  bool _isLoading = false;

  void _onChangePassword() async {
    String oldPassword = _oldPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      setState(() => _message = 'Vui lòng nhập mật khẩu cũ và mới');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _message = 'Xác nhận mật khẩu mới không khớp');
      return;
    }

    String? token = await SessionHelper.token;
    if (token == null) {
      setState(() => _message = 'Phiên làm việc hết hạn, vui lòng đăng nhập lại');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    var ret = await AuthRepository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      token: token,
    );

    setState(() => _isLoading = false);

    if (ret['code'] > 0) {
      if (!mounted) return;
      showMessage(context, 'Đổi mật khẩu thành công!');
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
            const Icon(Icons.password, size: 64, color: Colors.blueGrey),
            const SizedBox(height: 20),
            TextFormField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                prefixIcon: Icon(Icons.lock_clock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 15),
              Text(_message!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _onChangePassword,
              icon: const Icon(Icons.save),
              label: const Text('CẬP NHẬT MẬT KHẨU'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blueGrey.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

